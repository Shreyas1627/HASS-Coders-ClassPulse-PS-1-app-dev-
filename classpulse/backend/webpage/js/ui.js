// webpage/js/ui.js

document.addEventListener("DOMContentLoaded", () => {
    
    // --- 1. CONFIGURATION: LECTURE CONTENT ---
    const lectureContent = {
        "Normalization": ["1NF - Atomicity", "2NF - Partial Dependency", "3NF - Transitive Dependency", "BCNF"],
        "SQL Queries": ["SELECT & FROM", "JOIN Operations", "GROUP BY & HAVING", "Subqueries"],
        "Indexing": ["B-Trees", "Hash Indexing", "Clustered vs Non-Clustered"],
        "Transactions": ["ACID Properties", "Isolation Levels", "Deadlocks"]
    };

    // --- 2. ELEMENT SELECTORS ---
    const otpBoxes = document.querySelectorAll(".otp-box");
    const numKeys = document.querySelectorAll(".num-key");
    const backspace = document.getElementById("backspace");
    const joinBtn = document.getElementById("joinBtn");
    
    const startScanBtn = document.getElementById("startScanBtn");
    const qrOverlay = document.getElementById("qrOverlay");
    const closeScanner = document.getElementById("closeScanner");
    const scanStatus = document.getElementById("scanStatus");
    const uploadQrBtn = document.getElementById("uploadQrBtn");
    const qrFileInput = document.getElementById("qrFileInput");
    
    const currentTopicLabel = document.getElementById("currentTopic");
    const signalBtns = document.querySelectorAll(".signal-btn");
    const doubtModal = document.getElementById("doubtModal");
    const fabDoubt = document.getElementById("fabDoubt");
    const mainTopicSelect = document.getElementById("mainTopic");
    const subTopicSelect = document.getElementById("subTopic");
    const subTopicWrapper = document.getElementById("subTopicWrapper");
    const recentDoubtsContainer = document.getElementById("communityDoubts");

    let currentCode = "";
    let html5QrCode = null;

    // --- NEW: AI NOTIFICATION CONTAINER ---
    let displayedDoubtIds = new Set();
    const answersContainer = document.createElement("div");
    answersContainer.className = "fixed top-20 left-0 right-0 p-4 z-[100] pointer-events-none flex flex-col gap-3 items-center";
    document.body.appendChild(answersContainer);

    // --- 3. JOIN & VERIFICATION LOGIC ---
    // (Auto-fill code from URL if scanned from Teacher's screen)
    const urlParams = new URLSearchParams(window.location.search);
    const autoCode = urlParams.get('code');

    const updateOtpUI = () => {
        otpBoxes.forEach((box, i) => box.value = currentCode[i] || "");
        if (joinBtn) {
            if (currentCode.length === 4) {
                joinBtn.disabled = false;
                joinBtn.classList.replace("bg-[#2563EB]/30", "bg-[#2563EB]");
                joinBtn.classList.add("shadow-lg", "shadow-blue-200");
            } else {
                joinBtn.disabled = true;
                joinBtn.classList.replace("bg-[#2563EB]", "bg-[#2563EB]/30");
                joinBtn.classList.remove("shadow-lg", "shadow-blue-200");
            }
        }
    };

    const verifyAndJoin = async (code) => {
        if (!joinBtn) return;
        const originalText = joinBtn.innerText;
        joinBtn.innerText = "Verifying...";
        joinBtn.disabled = true;

        const success = await API.joinClass(code);
        if (success) {
            window.location.href = "session.html";
        } else {
            joinBtn.innerText = originalText;
            joinBtn.disabled = false;
            alert("Session not found. Please try again.");
            currentCode = "";
            updateOtpUI();
        }
    };

    if (autoCode && autoCode.length === 4) {
        currentCode = autoCode;
        updateOtpUI();
        setTimeout(() => { if(!joinBtn.disabled) verifyAndJoin(currentCode); }, 500);
    }

    // --- 4. NUMPAD INTERACTION ---
    numKeys.forEach(key => {
        key.onclick = () => {
            if (currentCode.length < 4) {
                currentCode += key.innerText;
                updateOtpUI();
            }
        };
    });

    if (backspace) {
        backspace.onclick = () => {
            currentCode = currentCode.slice(0, -1);
            updateOtpUI();
        };
    }

    if (joinBtn) {
        joinBtn.onclick = () => verifyAndJoin(currentCode);
    }

    // --- 5. QR SCANNER LOGIC ---
    const stopScanner = async () => {
        if (html5QrCode && html5QrCode.isScanning) {
            await html5QrCode.stop();
        }
        qrOverlay.classList.add("hidden");
    };

    if (startScanBtn) {
        startScanBtn.onclick = async () => {
            qrOverlay.classList.remove("hidden");
            scanStatus.innerText = "Align QR Code to scan";
            scanStatus.className = "text-white font-bold tracking-tight text-center mb-8";
            if (!html5QrCode) html5QrCode = new Html5Qrcode("reader");

            try {
                await html5QrCode.start(
                    { facingMode: "environment" }, 
                    { fps: 20, qrbox: { width: 250, height: 250 } },
                    async (text) => {
                        const match = text.match(/\d{4}/);
                        const code = match ? match[0] : (text.includes('code=') ? new URL(text).searchParams.get('code') : text.substring(0, 4));
                        await stopScanner();
                        currentCode = code;
                        updateOtpUI();
                        verifyAndJoin(code);
                    }
                );
            } catch (err) {
                alert("Camera access denied.");
                qrOverlay.classList.add("hidden");
            }
        };
        if (closeScanner) closeScanner.onclick = stopScanner;
    }

    // --- 6. SESSION PAGE: SIGNALS & MODALS ---
    if (mainTopicSelect) {
        mainTopicSelect.innerHTML = '<option value="">Choose Main Topic...</option>';
        Object.keys(lectureContent).forEach(topic => {
            const opt = document.createElement("option");
            opt.value = topic;
            opt.innerText = topic;
            mainTopicSelect.appendChild(opt);
        });

        mainTopicSelect.onchange = (e) => {
            const selected = e.target.value;
            subTopicSelect.innerHTML = '<option value="">Select Sub-topic...</option>';
            if (selected && lectureContent[selected]) {
                subTopicWrapper.classList.remove("hidden");
                lectureContent[selected].forEach(sub => {
                    const opt = document.createElement("option");
                    opt.value = sub;
                    opt.innerText = sub;
                    subTopicSelect.appendChild(opt);
                });
            } else {
                subTopicWrapper.classList.add("hidden");
            }
        };
    }

    signalBtns.forEach(btn => {
        btn.onclick = () => {
            const sig = btn.getAttribute("data-signal");
            if (sig === "got_it") {
                API.sendSignal(sig);
                if (navigator.vibrate) navigator.vibrate(50);
                btn.disabled = true;
                const oldText = btn.innerHTML;
                btn.innerHTML = `<span class="text-xl font-black text-green-500 italic">Received!</span>`;
                setTimeout(() => { btn.disabled = false; btn.innerHTML = oldText; }, 10000);
            } else {
                doubtModal.classList.remove("hidden");
            }
        };
    });

    if (fabDoubt) fabDoubt.onclick = () => doubtModal.classList.remove("hidden");
    
    document.getElementById("cancelDoubt")?.addEventListener("click", () => {
        doubtModal.classList.add("hidden");
    });

    document.getElementById("submitDoubt")?.addEventListener("click", async () => {
        const main = mainTopicSelect.value;
        const sub = subTopicSelect.value;
        const text = document.getElementById("doubtText").value;

        if (!main || !text) return alert("Please specify your doubt.");

        await API.submitDoubt(main, sub, text);
        doubtModal.classList.add("hidden");
        document.getElementById("doubtText").value = "";
        
        if (fabDoubt) {
            fabDoubt.innerHTML = "✅ Sent!";
            setTimeout(() => fabDoubt.innerHTML = "✋ Ask a Doubt", 2000);
        }
    });

    // --- 7. NEW: FETCH AI ANSWERS ---
    async function fetchAndDisplayAnswers() {
        const sessionCode = localStorage.getItem('session_code');
        const studentUuid = localStorage.getItem('student_uuid');
        
        if (!sessionCode || !studentUuid) return;

        try {
            const res = await fetch(`/api/student/my-doubts/${sessionCode}/${studentUuid}`);
            if (!res.ok) return;
            const data = await res.json();
            
            const answeredDoubts = data.answered_doubts || [];
            
            answeredDoubts.forEach(doubt => {
                if (doubt.ai_response && !displayedDoubtIds.has(doubt.id)) {
                    displayedDoubtIds.add(doubt.id); // Mark as shown
                    
                    const alertBox = document.createElement("div");
                    alertBox.className = "bg-white border-l-4 border-[#2563EB] shadow-2xl rounded-2xl p-5 max-w-sm w-full pointer-events-auto transform transition-all translate-y-0";
                    alertBox.innerHTML = `
                        <div class="flex items-center justify-between mb-3">
                            <span class="bg-blue-100 text-blue-700 text-[10px] font-black px-3 py-1.5 rounded-full uppercase tracking-widest">🤖 AI Tutor Answer</span>
                            <button class="text-gray-400 hover:text-gray-600 font-bold text-lg" onclick="this.parentElement.parentElement.remove()">✕</button>
                        </div>
                        <p class="text-xs text-gray-500 font-medium mb-2 pb-2 border-b border-gray-100">Your Doubt: <span class="italic">"${doubt.original_text}"</span></p>
                        <p class="text-sm font-bold text-gray-800 leading-relaxed">${doubt.ai_response}</p>
                    `;
                    answersContainer.appendChild(alertBox);
                }
            });
        } catch(e) { console.error("Polling error:", e); }
    }

    // --- 8. INITIALIZATION ---
    if (window.location.href.includes("session.html")) {
        API.startPolling();
        setInterval(fetchAndDisplayAnswers, 4000); // Check for answers every 4 seconds
    }
});