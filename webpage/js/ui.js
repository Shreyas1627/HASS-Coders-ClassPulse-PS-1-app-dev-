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
    // Index Page Elements
    const otpBoxes = document.querySelectorAll(".otp-box");
    const numKeys = document.querySelectorAll(".num-key");
    const backspace = document.getElementById("backspace");
    const joinBtn = document.getElementById("joinBtn");
    
    // Scanner Elements
    const startScanBtn = document.getElementById("startScanBtn");
    const qrOverlay = document.getElementById("qrOverlay");
    const closeScanner = document.getElementById("closeScanner");
    const scanStatus = document.getElementById("scanStatus");
    const uploadQrBtn = document.getElementById("uploadQrBtn");
    const qrFileInput = document.getElementById("qrFileInput");
    
    // Session Page Elements
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

    // --- 3. JOIN & VERIFICATION LOGIC ---
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

    // --- 5. QR SCANNER LOGIC (CAMERA + UPLOAD) ---
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
                        const code = match ? match[0] : text.substring(0, 4);
                        await stopScanner();
                        currentCode = code;
                        updateOtpUI();
                        verifyAndJoin(code);
                    }
                );
            } catch (err) {
                alert("Camera access denied. Please check your browser settings.");
                qrOverlay.classList.add("hidden");
            }
        };

        if (closeScanner) closeScanner.onclick = stopScanner;
    }

    // Gallery Upload Logic
    if (uploadQrBtn) {
        uploadQrBtn.onclick = () => qrFileInput.click();
        qrFileInput.onchange = async (e) => {
            if (e.target.files.length === 0) return;
            const file = e.target.files[0];
            scanStatus.innerText = "Scanning Image...";

            const fileScanner = new Html5Qrcode("reader");
            try {
                const text = await fileScanner.scanFile(file, true);
                const match = text.match(/\d{4}/);
                const code = match ? match[0] : text.substring(0, 4);
                
                await stopScanner();
                currentCode = code;
                updateOtpUI();
                verifyAndJoin(code);
            } catch (err) {
                scanStatus.innerText = "No QR Code found in image.";
                scanStatus.className = "text-red-400 font-bold text-center mb-8";
            }
        };
    }

    // --- 6. SESSION PAGE: SIGNALS & MODALS ---
    if (mainTopicSelect) {
        // Populate Topics
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
                
                // Freeze visual
                btn.disabled = true;
                const oldText = btn.innerHTML;
                btn.innerHTML = `<span class="text-xl font-black text-green-500 italic">Received!</span>`;
                setTimeout(() => { btn.disabled = false; btn.innerHTML = oldText; }, 10000);
            } else {
                // "May Be" or "Not Understood" triggers Modal
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

    // --- 7. COMMUNITY TICKER & UPVOTING ---
    async function refreshDoubts() {
        if (!recentDoubtsContainer) return;
        const doubts = await API.fetchRecentDoubts();
        
        if (doubts.length > 0) {
            document.getElementById("noDoubtsPlaceholder")?.remove();
            recentDoubtsContainer.innerHTML = doubts.map(d => `
                <div class="flex-shrink-0 bg-white border border-blue-100 rounded-3xl p-5 w-64 shadow-sm flex flex-col justify-between transition-all">
                    <div>
                        <span class="text-[9px] font-black text-blue-400 uppercase tracking-widest">${d.topic || 'General'}</span>
                        <p class="text-xs font-bold text-gray-700 mt-1 line-clamp-2 italic leading-relaxed">"${d.text}"</p>
                    </div>
                    <div class="flex justify-between items-center mt-4">
                        <span class="text-[10px] font-black text-gray-400 uppercase tracking-tight">${d.upvotes || 0} Me Toos</span>
                        <button onclick="handleUpvote('${d.id}', this)" class="bg-blue-50 text-[#2563EB] text-[9px] font-black px-4 py-2 rounded-xl active:scale-90 transition-all uppercase tracking-tight">✋ Me Too</button>
                    </div>
                </div>
            `).join('');
        }
    }

    window.handleUpvote = async (id, btn) => {
        btn.innerText = "✅";
        btn.disabled = true;
        await API.upvoteDoubt(id);
        if (navigator.vibrate) navigator.vibrate(50);
    };

    // --- 8. INITIALIZATION ---
    if (window.location.href.includes("session.html")) {
        API.startPolling();
        setInterval(refreshDoubts, 5000);
    }
});