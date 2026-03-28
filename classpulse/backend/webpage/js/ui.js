// ui.js - ClassPulse Web Client UI Logic
(function() {
    const page = document.title.includes('Join') ? 'join' : 
                 document.title.includes('Live') ? 'session' : 'ended';

    if (page === 'join') initJoinPage();
    else if (page === 'session') initSessionPage();

    // ═══════════════════════════════════════════════════════════════════
    // JOIN PAGE
    // ═══════════════════════════════════════════════════════════════════
    function initJoinPage() {
        // Check for auto-join code in URL (from QR scan)
        const urlParams = new URLSearchParams(window.location.search);
        const autoCode = urlParams.get('code');

        const boxes = document.querySelectorAll('.otp-box');
        const numKeys = document.querySelectorAll('.num-key:not(.empty):not(.backspace)');
        const backspace = document.getElementById('backspace');
        const joinBtn = document.getElementById('joinBtn');
        const startScanBtn = document.getElementById('startScanBtn');
        const qrOverlay = document.getElementById('qrOverlay');
        const closeScanner = document.getElementById('closeScanner');
        const uploadQrBtn = document.getElementById('uploadQrBtn');
        const qrFileInput = document.getElementById('qrFileInput');

        let pin = '';
        let scanner = null;

        function updateDisplay() {
            boxes.forEach((box, i) => {
                box.value = pin[i] || '';
                box.classList.toggle('filled', !!pin[i]);
                box.classList.toggle('active', i === pin.length && pin.length < 4);
            });
            if (pin.length === 4) {
                joinBtn.classList.remove('disabled');
                joinBtn.classList.add('enabled');
                joinBtn.disabled = false;
            } else {
                joinBtn.classList.add('disabled');
                joinBtn.classList.remove('enabled');
                joinBtn.disabled = true;
            }
        }

        numKeys.forEach(key => {
            key.addEventListener('click', () => {
                if (pin.length < 4) {
                    pin += key.textContent;
                    updateDisplay();
                }
            });
        });

        backspace.addEventListener('click', () => {
            if (pin.length > 0) {
                pin = pin.slice(0, -1);
                updateDisplay();
            }
        });

        // Physical keyboard support
        document.addEventListener('keydown', e => {
            if (page !== 'join') return;
            if (e.key >= '0' && e.key <= '9' && pin.length < 4) {
                pin += e.key;
                updateDisplay();
            } else if (e.key === 'Backspace') {
                pin = pin.slice(0, -1);
                updateDisplay();
            } else if (e.key === 'Enter' && pin.length === 4) {
                joinSession();
            }
        });

        joinBtn.addEventListener('click', joinSession);

        async function joinSession() {
            if (pin.length !== 4) return;
            joinBtn.textContent = 'Joining...';
            joinBtn.disabled = true;

            try {
                const data = await api.join(pin, 'web_student_' + Date.now());
                if (data.status === 'success') {
                    localStorage.setItem('session_code', pin);
                    localStorage.setItem('student_uuid', data.student_uuid);
                    localStorage.setItem('session_topic', data.topic || '');
                    localStorage.setItem('session_subject', data.subject || '');
                    window.location.href = 'session.html';
                } else {
                    alert('Invalid or inactive session code.');
                    joinBtn.textContent = 'Join Session';
                    joinBtn.disabled = false;
                }
            } catch (err) {
                alert('Could not connect to server.');
                joinBtn.textContent = 'Join Session';
                joinBtn.disabled = false;
            }
        }

        // QR Scanner
        startScanBtn.addEventListener('click', openScanner);
        closeScanner.addEventListener('click', closeQR);

        function openScanner() {
            qrOverlay.classList.add('visible');
            scanner = new Html5Qrcode("reader");
            scanner.start(
                { facingMode: "environment" },
                { fps: 10, qrbox: 220 },
                (decoded) => {
                    const code = extractCodeFromQR(decoded);
                    closeQR();
                    pin = code;
                    updateDisplay();
                    joinSession();
                },
                () => {}
            ).catch(() => {
                document.getElementById('scanStatus').textContent = 'Camera not available';
            });
        }

        function closeQR() {
            qrOverlay.classList.remove('visible');
            if (scanner) {
                scanner.stop().catch(() => {});
                scanner = null;
            }
        }

        uploadQrBtn.addEventListener('click', () => qrFileInput.click());
        qrFileInput.addEventListener('change', async (e) => {
            const file = e.target.files[0];
            if (!file) return;
            try {
                const tmpScanner = new Html5Qrcode("reader");
                const decoded = await tmpScanner.scanFile(file, true);
                const code = extractCodeFromQR(decoded);
                closeQR();
                pin = code;
                updateDisplay();
                joinSession();
            } catch {
                alert('Could not read QR code from image.');
            }
        });

        updateDisplay();

        // Auto-join if code came from URL query param (QR scan redirect)
        if (autoCode && autoCode.length === 4 && /^\d{4}$/.test(autoCode)) {
            pin = autoCode;
            updateDisplay();
            joinSession();
        }
    }

    // Extract session code from QR data (URL or plain code)
    function extractCodeFromQR(decoded) {
        try {
            const url = new URL(decoded);
            const codeParam = url.searchParams.get('code');
            if (codeParam && /^\d{4}$/.test(codeParam)) return codeParam;
        } catch (_) {}
        // Fallback: take last 4 digits
        const digits = decoded.replace(/\D/g, '');
        return digits.length >= 4 ? digits.slice(-4) : decoded;
    }

    // ═══════════════════════════════════════════════════════════════════
    // SESSION PAGE
    // ═══════════════════════════════════════════════════════════════════
    function initSessionPage() {
        const sessionCode = localStorage.getItem('session_code');
        const studentUuid = localStorage.getItem('student_uuid');
        const topic = localStorage.getItem('session_topic') || 'Live Session';

        if (!sessionCode || !studentUuid) {
            window.location.href = 'index.html';
            return;
        }

        // Display topic
        const topicEl = document.getElementById('currentTopic');
        if (topicEl) topicEl.textContent = topic;

        // Signal buttons
        const signalBtns = document.querySelectorAll('.signal-btn');
        let selectedSignal = null;
        let cooldownActive = false;

        signalBtns.forEach(btn => {
            btn.addEventListener('click', async () => {
                if (cooldownActive) return;
                const signal = btn.dataset.signal;

                // If not got_it, check for doubt then send signal
                if (signal !== 'got_it') {
                    openDoubtModal(signal);
                    return;
                }

                // Send got_it directly
                selectButton(btn, signal);
                await api.signal(sessionCode, studentUuid, 'got_it');
                startCooldown();
            });
        });

        function selectButton(btn, signal) {
            signalBtns.forEach(b => b.classList.remove('selected'));
            btn.classList.add('selected');
            selectedSignal = signal;
        }

        function startCooldown() {
            cooldownActive = true;
            signalBtns.forEach(b => {
                b.style.opacity = '0.5';
                b.style.pointerEvents = 'none';
            });
            setTimeout(() => {
                cooldownActive = false;
                signalBtns.forEach(b => {
                    b.style.opacity = '1';
                    b.style.pointerEvents = 'auto';
                });
            }, 30000);
        }

        // Doubt Modal
        const fabDoubt = document.getElementById('fabDoubt');
        const doubtModal = document.getElementById('doubtModal');
        const cancelDoubt = document.getElementById('cancelDoubt');
        const submitDoubt = document.getElementById('submitDoubt');
        const doubtText = document.getElementById('doubtText');
        let pendingSignal = null;

        fabDoubt.addEventListener('click', () => openDoubtModal());
        cancelDoubt.addEventListener('click', closeDoubtModal);

        function openDoubtModal(signal) {
            pendingSignal = signal || null;
            doubtText.value = '';
            doubtModal.classList.add('visible');
        }

        function closeDoubtModal() {
            doubtModal.classList.remove('visible');
            pendingSignal = null;
        }

        submitDoubt.addEventListener('click', async () => {
            const text = doubtText.value.trim();

            // Send signal if we have one pending
            if (pendingSignal) {
                const apiSignal = pendingSignal === 'may_be' ? 'sort_of' : 'lost';
                await api.signal(sessionCode, studentUuid, apiSignal);

                // Visually select the button
                const btn = document.querySelector(`.signal-btn[data-signal="${pendingSignal}"]`);
                if (btn) selectButton(btn, pendingSignal);
                startCooldown();
            }

            // Send doubt text
            if (text) {
                await api.doubt(sessionCode, studentUuid, text);
            }

            closeDoubtModal();
        });

        // Poll for session end
        setInterval(async () => {
            try {
                const status = await api.pollStatus(sessionCode);
                if (status.status === 'closed') {
                    window.location.href = 'ended.html';
                }
            } catch {}
        }, 5000);
    }
})();