// api.js - ClassPulse Web Client API
const API_BASE = window.location.origin;

const api = {
    async join(session_code, roll_number) {
        const res = await fetch(`${API_BASE}/api/student/join`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ session_code, roll_number })
        });
        return res.json();
    },

    async signal(session_code, student_uuid, signal_type) {
        const res = await fetch(`${API_BASE}/api/student/signal`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                session_code,
                student_uuid,
                signal: signal_type
            })
        });
        return res.json();
    },

    async doubt(session_code, student_uuid, text, parent_id = null) {
        const body = { session_code, student_uuid, text };
        if (parent_id) body.parent_id = parent_id;
        
        const res = await fetch(`${API_BASE}/api/student/doubt`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });
        return res.json();
    },

    async pollStatus(session_code) {
        const res = await fetch(`${API_BASE}/api/student/poll/status/${session_code}`);
        return res.json();
    },

    async checkSession(session_code) {
        const res = await fetch(`${API_BASE}/api/teacher/session/check/${session_code}`);
        return res.json();
    }
};