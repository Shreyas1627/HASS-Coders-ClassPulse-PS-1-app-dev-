const API = {
    async joinClass(code) {
        // FIXED: Added /student prefix and a dummy roll_number to pass validation
        const res = await fetch('/api/student/join', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ session_code: code, roll_number: "Anon-Web" })
        });
        if (!res.ok) return false;
        const data = await res.json();
        localStorage.setItem('student_uuid', data.student_uuid);
        localStorage.setItem('session_code', code);
        return true;
    },
    async sendSignal(signal) {
        // FIXED: Added /student prefix
        fetch('/api/student/signal', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ 
                session_code: localStorage.getItem('session_code'), 
                student_uuid: localStorage.getItem('student_uuid'), 
                signal: signal, 
                milestone_id: "current" 
            })
        });
    },
    async submitDoubt(main, sub, text) {
        // FIXED: Added /student prefix and matched your backend DoubtReq schema
        const res = await fetch('/api/student/doubt', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ 
                session_code: localStorage.getItem('session_code'), 
                student_uuid: localStorage.getItem('student_uuid'), 
                
                text: `[${sub}] ${text}`, // Merged sub-topic into text
                parent_id: null
            })
        });
        return await res.json();
    },
    startPolling() {
        setInterval(async () => {
            try {
                const res = await fetch(`/api/student/poll/status/${localStorage.getItem('session_code')}`);
                const data = await res.json();
                if (data.status === "closed") window.location.href = "ended.html";
            } catch (e) {}
        }, 3000);
    }
};