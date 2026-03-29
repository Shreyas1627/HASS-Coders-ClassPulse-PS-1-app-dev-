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

            const performJoin = async (lat, lng) => {
                try {
                    const data = await api.join(pin, 'web_student_' + Date.now(), lat, lng);
                    if (data.status === 'success') {
                        localStorage.setItem('session_code', pin);
                        localStorage.setItem('student_uuid', data.student_uuid);
                        localStorage.setItem('session_topic', data.topic || '');
                        localStorage.setItem('session_subject', data.subject || '');
                        localStorage.setItem('session_class_name', data.class_name || '');
                        localStorage.setItem('session_subtopic', data.subtopic || '');
                        localStorage.setItem('session_subtopic_index', data.current_subtopic_index || 0);
                        window.location.href = 'session.html';
                    } else {
                        alert(data.detail || 'Invalid or inactive session code.');
                        joinBtn.textContent = 'Join Session';
                        joinBtn.disabled = false;
                    }
                } catch (err) {
                    alert('Could not connect to server.');
                    joinBtn.textContent = 'Join Session';
                    joinBtn.disabled = false;
                }
            };

            if (navigator.geolocation) {
                navigator.geolocation.getCurrentPosition(
                    pos => performJoin(pos.coords.latitude, pos.coords.longitude),
                    err => performJoin(null, null),
                    { timeout: 5000 }
                );
            } else {
                performJoin(null, null);
            }
        }

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

        if (autoCode && autoCode.length === 4 && /^\d{4}$/.test(autoCode)) {
            pin = autoCode;
            updateDisplay();
            joinSession();
        }
    }

    function extractCodeFromQR(decoded) {
        try {
            const url = new URL(decoded);
            const codeParam = url.searchParams.get('code');
            if (codeParam && /^\d{4}$/.test(codeParam)) return codeParam;
        } catch (_) {}
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
        const subject = localStorage.getItem('session_subject') || 'Subject';
        const className = localStorage.getItem('session_class_name') || 'Class';
        const subtopicStr = localStorage.getItem('session_subtopic') || '';
        const subtopics = subtopicStr ? subtopicStr.split(',').map(s => s.trim()).filter(Boolean) : [];
        let currentSubtopicIndex = parseInt(localStorage.getItem('session_subtopic_index') || '0', 10);

        if (!sessionCode || !studentUuid) {
            window.location.href = 'index.html';
            return;
        }

        // ── Populate session info ─────────────────────────────────────
        document.getElementById('sessionSubject').textContent = subject;
        document.getElementById('sessionMeta').textContent = className + ' \u00B7 Live';

        // ── Back button ───────────────────────────────────────────────
        document.getElementById('backBtn').addEventListener('click', () => {
            if (confirm('Leave session? You can rejoin using the same code.')) {
                window.location.href = 'index.html';
            }
        });

        // ── Subtopic Tracker ──────────────────────────────────────────
        const trackerEl = document.getElementById('subtopicTracker');
        const dotsEl = document.getElementById('progressDots');
        const colsEl = document.getElementById('topicColumns');

        function renderSubtopicTracker(idx) {
            if (!subtopics.length || !trackerEl) return;
            trackerEl.classList.add('visible');

            dotsEl.innerHTML = '';
            for (let i = 0; i < subtopics.length; i++) {
                if (i > 0) {
                    const line = document.createElement('div');
                    line.className = 'line' + (i <= idx ? ' done' : '');
                    dotsEl.appendChild(line);
                }
                const dot = document.createElement('div');
                dot.className = 'dot' + (i < idx ? ' done' : i === idx ? ' active' : '');
                dotsEl.appendChild(dot);
            }

            const doneName = idx > 0 ? subtopics[idx - 1] : '\u2014';
            const activeName = idx < subtopics.length ? subtopics[idx] : subtopics[subtopics.length - 1];
            const nextName = idx < subtopics.length - 1 ? subtopics[idx + 1] : '\u2014';

            colsEl.innerHTML =
                '<div class="topic-col">' +
                    '<div class="topic-col-icon">\u2705</div>' +
                    '<div class="topic-col-label lbl-done">Done</div>' +
                    '<div class="topic-col-name">' + doneName + '</div>' +
                '</div>' +
                '<div class="topic-col">' +
                    '<div class="topic-col-icon">\u25B6\uFE0F</div>' +
                    '<div class="topic-col-label lbl-active">Active</div>' +
                    '<div class="topic-col-name">' + activeName + '</div>' +
                '</div>' +
                '<div class="topic-col">' +
                    '<div class="topic-col-icon">\u23E9</div>' +
                    '<div class="topic-col-label lbl-next">Next</div>' +
                    '<div class="topic-col-name">' + nextName + '</div>' +
                '</div>';
        }
        renderSubtopicTracker(currentSubtopicIndex);

        // Populate doubt modal topic dropdown
        const mainTopicSelect = document.getElementById('mainTopic');
        if (mainTopicSelect && subtopics.length) {
            mainTopicSelect.innerHTML = '<option value="">Choose Subtopic...</option>';
            subtopics.forEach(st => {
                const opt = document.createElement('option');
                opt.value = st;
                opt.textContent = st;
                mainTopicSelect.appendChild(opt);
            });
        }

        // ── Signal Buttons ────────────────────────────────────────────
        const signalBtns = document.querySelectorAll('.signal-btn');
        let selectedSignal = null;
        let cooldownActive = false;
        let cooldownRemaining = 0;
        let cooldownInterval = null;
        let hasUsedChange = false;
        let isChanging = false;
        const COOLDOWN_DURATION = 30;

        const confirmEl = document.getElementById('signalConfirm');
        const cooldownBar = document.getElementById('cooldownBar');
        const cooldownText = document.getElementById('cooldownText');
        const cooldownFill = document.getElementById('cooldownFill');
        const cooldownChangeEl = document.getElementById('cooldownChange');

        signalBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                if (cooldownActive && !isChanging) return;
                const signal = btn.dataset.signal;

                if (signal !== 'got_it') {
                    openDoubtModal(signal);
                    return;
                }

                // Send got_it directly
                selectSignal(btn, 'got_it');
                api.signal(sessionCode, studentUuid, 'got_it');
                startCooldown('#10B981');
                showToast('\u2705 Response sent!');
            });
        });

        function selectSignal(btn, signal) {
            signalBtns.forEach(b => {
                b.classList.remove('selected');
                if (cooldownActive || true) b.classList.add('disabled');
            });
            btn.classList.add('selected');
            btn.classList.remove('disabled');
            selectedSignal = signal;
            isChanging = false;
            showConfirmation(signal);
        }

        function showConfirmation(signal) {
            let color, label, iconName;
            if (signal === 'got_it') {
                color = '#10B981'; label = 'You responded: Got it'; iconName = 'check_circle';
            } else if (signal === 'sort_of') {
                color = '#F59E0B'; label = 'You responded: Sort of'; iconName = 'help';
            } else {
                color = '#EF4444'; label = 'You responded: Lost'; iconName = 'cancel';
            }

            const canChange = cooldownActive && !hasUsedChange && !isChanging;
            confirmEl.style.background = color + '14';
            confirmEl.style.border = '1px solid ' + color + '33';
            confirmEl.innerHTML =
                '<span class="material-icons-round confirm-icon" style="color:' + color + '">' + iconName + '</span>' +
                '<span class="confirm-text" style="color:' + color + '">' + label + '</span>' +
                (canChange
                    ? '<button class="change-btn" id="changeSignalBtn" style="color:' + color + ';background:' + color + '1F;">Change</button>'
                    : '');
            confirmEl.classList.add('visible');

            if (canChange) {
                document.getElementById('changeSignalBtn').addEventListener('click', () => {
                    hasUsedChange = true;
                    isChanging = true;
                    selectedSignal = null;
                    confirmEl.classList.remove('visible');
                    signalBtns.forEach(b => b.classList.remove('selected', 'disabled'));
                    cooldownChangeEl.textContent = 'Change used';
                    cooldownChangeEl.style.color = '#94A3B8';
                });
            }
        }

        function startCooldown(color) {
            cooldownActive = true;
            cooldownRemaining = COOLDOWN_DURATION;
            hasUsedChange = false;
            isChanging = false;

            signalBtns.forEach(b => {
                if (!b.classList.contains('selected')) b.classList.add('disabled');
            });

            cooldownBar.classList.add('visible');
            cooldownFill.style.background = color;
            cooldownFill.style.width = '100%';
            cooldownChangeEl.textContent = 'You can change once';
            cooldownChangeEl.style.color = color;

            if (cooldownInterval) clearInterval(cooldownInterval);
            cooldownInterval = setInterval(() => {
                cooldownRemaining--;
                cooldownText.textContent = 'Next response in ' + cooldownRemaining + 's';
                cooldownFill.style.width = ((cooldownRemaining / COOLDOWN_DURATION) * 100) + '%';

                if (selectedSignal) showConfirmation(selectedSignal);

                if (cooldownRemaining <= 0) {
                    clearInterval(cooldownInterval);
                    cooldownActive = false;
                    hasUsedChange = false;
                    cooldownBar.classList.remove('visible');
                    confirmEl.classList.remove('visible');
                    signalBtns.forEach(b => b.classList.remove('disabled', 'selected'));
                    selectedSignal = null;
                }
            }, 1000);
        }

        // ── Doubt Modal ───────────────────────────────────────────────
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

            if (pendingSignal) {
                const apiSignal = pendingSignal === 'sort_of' ? 'sort_of' : 'lost';
                await api.signal(sessionCode, studentUuid, apiSignal);

                const btn = document.querySelector('.signal-btn[data-signal="' + pendingSignal + '"]');
                if (btn) selectSignal(btn, pendingSignal);

                const color = pendingSignal === 'sort_of' ? '#F59E0B' : '#EF4444';
                startCooldown(color);
                showToast(text ? 'Doubt sent! \uD83D\uDCDD' : 'Response sent!');
            }

            if (text) {
                await api.doubt(sessionCode, studentUuid, text);
                if (!pendingSignal) showToast('Doubt sent! \uD83D\uDCDD');
            }

            closeDoubtModal();
        });

        // ── Questions Panel ───────────────────────────────────────────
        const questionsPanel = document.getElementById('questionsPanel');
        const questionsHandle = document.getElementById('questionsHandle');
        const questionsList = document.getElementById('questionsList');
        const questionsCount = document.getElementById('questionsCount');
        let panelOpen = false;
        const upvotedQuestions = new Set();

        questionsHandle.addEventListener('click', () => {
            panelOpen = !panelOpen;
            questionsPanel.classList.toggle('collapsed', !panelOpen);
        });

        function renderQuestions(questions) {
            questionsCount.textContent = questions.length;
            if (!questions.length) {
                questionsList.innerHTML = '<div class="q-empty">No questions yet. Be the first to ask!</div>';
                return;
            }
            const sorted = [...questions].sort((a, b) => (b.upvotes || 0) - (a.upvotes || 0));
            questionsList.innerHTML = sorted.map(q => {
                const isUpvoted = upvotedQuestions.has(q.id);
                return '<div class="q-card">' +
                    '<div class="q-upvote' + (isUpvoted ? ' active' : '') + '" data-qid="' + q.id + '">' +
                        '<span class="material-icons-round">expand_less</span>' +
                        '<span class="q-upvote-count">' + (q.upvotes || 0) + '</span>' +
                    '</div>' +
                    '<div class="q-text">' +
                        (q.translated_text || q.original_text || '') +
                        (q.ai_response ? '<div class="q-ai-badge" data-answer="' + encodeURIComponent(q.ai_response) + '">\u2728 AI Answer</div>' : '') +
                    '</div>' +
                '</div>';
            }).join('');

            questionsList.querySelectorAll('.q-upvote').forEach(el => {
                el.addEventListener('click', async () => {
                    const qid = el.dataset.qid;
                    if (upvotedQuestions.has(qid)) return;
                    upvotedQuestions.add(qid);
                    el.classList.add('active');
                    const countEl = el.querySelector('.q-upvote-count');
                    countEl.textContent = parseInt(countEl.textContent) + 1;
                    await api.upvote(qid);
                });
            });

            questionsList.querySelectorAll('.q-ai-badge').forEach(el => {
                el.addEventListener('click', () => {
                    alert(decodeURIComponent(el.dataset.answer));
                });
            });
        }

        // ── Toast ─────────────────────────────────────────────────────
        const toastEl = document.getElementById('toast');
        let toastTimeout = null;
        function showToast(message) {
            toastEl.textContent = message;
            toastEl.classList.add('visible');
            if (toastTimeout) clearTimeout(toastTimeout);
            toastTimeout = setTimeout(() => {
                toastEl.classList.remove('visible');
            }, 2500);
        }

        // ── Polling ───────────────────────────────────────────────────
        async function pollSession() {
            try {
                const status = await api.pollStatus(sessionCode);
                if (status.status === 'closed') {
                    window.location.href = 'ended.html';
                    return;
                }
                if (subtopics.length && status.current_subtopic_index !== undefined) {
                    const newIdx = status.current_subtopic_index;
                    if (newIdx !== currentSubtopicIndex) {
                        currentSubtopicIndex = newIdx;
                        localStorage.setItem('session_subtopic_index', newIdx);
                        renderSubtopicTracker(newIdx);
                        showToast('\u27A1\uFE0F Teacher moved to: ' + (subtopics[newIdx] || ''));
                    }
                }
            } catch {}

            try {
                const qData = await api.getQuestions(sessionCode);
                if (qData && qData.questions) {
                    renderQuestions(qData.questions);
                }
            } catch {}
        }

        pollSession();
        setInterval(pollSession, 5000);

        // ══════════════════════════════════════════════════════════════
        // TAB LOCK MECHANISM
        // ══════════════════════════════════════════════════════════════
        const lockOverlay = document.getElementById('lockOverlay');
        const lockWarningCount = document.getElementById('lockWarningCount');
        const lockReturnBtn = document.getElementById('lockReturnBtn');
        let tabSwitchCount = 0;

        function showLockScreen() {
            tabSwitchCount++;
            lockWarningCount.textContent = '\u26A0\uFE0F Warning ' + tabSwitchCount + ' \u2014 Your teacher has been notified';
            lockOverlay.classList.add('visible');
        }

        function hideLockScreen() {
            lockOverlay.classList.remove('visible');
        }

        // Detect tab switch via Page Visibility API
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                showLockScreen();
            }
        });

        // Detect window blur (alt-tab, app switching)
        window.addEventListener('blur', () => {
            // Small delay to avoid false positives from doubt modal focus
            setTimeout(() => {
                if (document.hidden) showLockScreen();
            }, 200);
        });

        // Return button
        lockReturnBtn.addEventListener('click', hideLockScreen);

        // Prevent right-click context menu
        document.addEventListener('contextmenu', e => e.preventDefault());

        // Prevent common keyboard shortcuts for tab/window switching
        document.addEventListener('keydown', e => {
            if (
                (e.ctrlKey && e.key === 'Tab') ||
                (e.ctrlKey && (e.key === 'w' || e.key === 'W')) ||
                (e.ctrlKey && (e.key === 't' || e.key === 'T')) ||
                (e.key === 'F5') ||
                (e.ctrlKey && (e.key === 'r' || e.key === 'R'))
            ) {
                e.preventDefault();
            }
        });
    }
})();