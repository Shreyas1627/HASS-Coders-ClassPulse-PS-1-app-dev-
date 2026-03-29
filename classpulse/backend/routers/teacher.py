from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import List, Optional
from core.database import supabase
from core.config import settings
from schemas.pydantic_models import SessionCreateReq, SessionStartReq, DoubtAnswerReq, QuestionAddressedReq
import random
import qrcode
import io

router = APIRouter()

# --- Generate QR Code for Session ---
@router.get("/session/qr/{session_code}")
async def generate_session_qr(session_code: str):
    """Generate a QR code PNG that encodes the student web join URL"""
    base = settings.BASE_URL.rstrip("/")
    join_url = f"{base}/student_web/?code={session_code}"

    qr = qrcode.QRCode(version=1, error_correction=qrcode.constants.ERROR_CORRECT_L, box_size=10, border=3)
    qr.add_data(join_url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return StreamingResponse(buf, media_type="image/png")


@router.post("/session/create")
async def create_session(req: SessionCreateReq):
    code = str(random.randint(1000, 9999))
    data = {
        "teacher_id": req.teacher_id,
        "session_code": code,
        "subject": req.subject,
        "class_name": req.class_name,
        "topic": req.topic,
        "subtopic": req.subtopic,
        "latitude": req.latitude,
        "longitude": req.longitude,
        "is_active": True,
    }
    if req.scheduled_at:
        data["scheduled_at"] = req.scheduled_at

    res = supabase.table("sessions").insert(data).execute()
    if not res.data:
        raise HTTPException(status_code=400, detail="Could not create session.")

    session = res.data[0]
    return {
        "status": "success",
        "session_code": code,
        "session_id": session["id"],
        "class_name": req.class_name,
        "subject": req.subject,
        "topic": req.topic,
        "message": "Class is live!"
    }

# --- Active Sessions (for homepage) ---
@router.get("/sessions/active/{teacher_id}")
async def get_active_sessions(teacher_id: str):
    res = supabase.table("sessions").select("*").eq("teacher_id", teacher_id).eq("is_active", True).order("created_at", desc=True).execute()
    return {"sessions": res.data}

# --- All Active Sessions (any teacher) ---
@router.get("/sessions/active")
async def get_all_active_sessions():
    res = supabase.table("sessions").select("*").eq("is_active", True).order("created_at", desc=True).execute()
    return {"sessions": res.data}

# --- Session History ---
@router.get("/sessions/history/{teacher_id}")
async def get_session_history(teacher_id: str):
    res = supabase.table("sessions").select("*").eq("teacher_id", teacher_id).eq("is_active", False).not_.is_("session_code", "null").order("created_at", desc=True).execute()
    sessions = res.data

    # Group by class_name -> subject
    grouped = {}
    for s in sessions:
        cn = s.get("class_name") or "Unnamed Class"
        subj = s.get("subject") or "General"
        if cn not in grouped:
            grouped[cn] = {}
        if subj not in grouped[cn]:
            grouped[cn][subj] = []

        # Get attendance count for this session
        att_res = supabase.table("attendance").select("id", count="exact").eq("session_code", s["session_code"]).execute()
        att_count = att_res.count if att_res.count else 0

        grouped[cn][subj].append({
            **s,
            "attended": att_count,
        })

    return {"history": grouped}

# --- Students aggregated from attendance/signals ---
@router.get("/students/{teacher_id}")
async def get_students(teacher_id: str):
    # Get all sessions for this teacher
    sessions_res = supabase.table("sessions").select("session_code,class_name").eq("teacher_id", teacher_id).not_.is_("session_code", "null").execute()
    sessions = sessions_res.data

    if not sessions:
        return {"students_by_class": {}}

    class_map = {s["session_code"]: s.get("class_name", "Unknown") for s in sessions}
    codes = list(class_map.keys())

    # Get all attendance records for these sessions
    att_res = supabase.table("attendance").select("roll_number,session_code").in_("session_code", codes).execute()

    # Get all signals for these sessions
    sig_res = supabase.table("signals").select("student_uuid,session_code,signal_type").in_("session_code", codes).execute()

    # Map student_uuid -> roll_number from attendance
    uuid_to_roll = {}
    for a in att_res.data:
        # Find linked uuid from signals that share the session
        pass

    # Build per-class, per-roll-number stats
    students_by_class = {}
    roll_sessions = {}  # roll_number -> list of session_codes they attended
    for a in att_res.data:
        rn = a["roll_number"]
        sc = a["session_code"]
        cn = class_map.get(sc, "Unknown")
        if cn not in students_by_class:
            students_by_class[cn] = {}
        if rn not in students_by_class[cn]:
            students_by_class[cn][rn] = {"sessions_attended": 0, "signals": []}
        students_by_class[cn][rn]["sessions_attended"] += 1

    # Count signals per student
    for s in sig_res.data:
        # Match by session_code + student_uuid -> linked via attendance
        pass

    # Format for frontend
    result = {}
    colors = [0xFF6366F1, 0xFF8B5CF6, 0xFF06B6D4, 0xFFF59E0B, 0xFF10B981, 0xFFEC4899, 0xFF3B82F6, 0xFFF97316, 0xFF14B8A6, 0xFFA855F7]
    for cn, students in students_by_class.items():
        result[cn] = []
        for i, (rn, data) in enumerate(students.items()):
            initials = ''.join([w[0].upper() for w in rn.split('_')[:2]]) if '_' in rn else rn[:2].upper()
            result[cn].append({
                "name": rn,
                "initials": initials,
                "avatar_color": colors[i % len(colors)],
                "insight": f"Sessions attended: {data['sessions_attended']}",
                "is_flagged": False,
            })

    return {"students_by_class": result}

# --- Dashboard Poll ---
@router.get("/dashboard/poll/{session_code}")
async def poll_dashboard(session_code: str):
    signals_res = supabase.table("signals").select("signal_type").eq("session_code", session_code).execute()
    signals = signals_res.data

    got_it = len([s for s in signals if s['signal_type'] == 'got_it'])
    sort_of = len([s for s in signals if s['signal_type'] == 'sort_of'])
    lost = len([s for s in signals if s['signal_type'] == 'lost'])

    questions_res = supabase.table("questions").select("id,original_text,translated_text,status,ai_response,upvotes,is_addressed,student_uuid,subtopic,created_at").eq("session_code", session_code).neq("status", "spam").order("upvotes", desc=True).execute()

    attendance_res = supabase.table("attendance").select("student_uuid, joined_at, is_blocked", count="exact").eq("session_code", session_code).execute()
    total = attendance_res.count if attendance_res.count else (got_it + sort_of + lost)

    # Get session info for subtopic data
    session_res = supabase.table("sessions").select("subtopic,current_subtopic_index").eq("session_code", session_code).execute()
    session_data = session_res.data[0] if session_res.data else {}

    return {
        "got_it": got_it,
        "sort_of": sort_of,
        "lost": lost,
        "total": total,
        "students": attendance_res.data,
        "questions": questions_res.data,
        "subtopic": session_data.get("subtopic", ""),
        "current_subtopic_index": session_data.get("current_subtopic_index", 0),
    }

# --- Unblock Student ---
class UnblockStudentReq(BaseModel):
    session_code: str
    student_uuid: str

@router.post("/student/unblock")
async def unblock_student(req: UnblockStudentReq):
    supabase.table("attendance").update({
        "is_blocked": False,
        "warnings": 0 
    }).eq("session_code", req.session_code).eq("student_uuid", req.student_uuid).execute()
    return {"status": "success", "message": "Student unblocked"}

# --- End Session ---
@router.post("/session/end/{session_code}")
async def end_session(session_code: str):
    supabase.table("sessions").update({"is_active": False}).eq("session_code", session_code).execute()

    # --- Use signal_history for ACCUMULATED counts (full session picture) ---
    history_res = supabase.table("signal_history").select("signal_type").eq("session_code", session_code).execute()
    history = history_res.data
    hist_got_it = len([s for s in history if s['signal_type'] == 'got_it'])
    hist_sort_of = len([s for s in history if s['signal_type'] == 'sort_of'])
    hist_lost = len([s for s in history if s['signal_type'] == 'lost'])

    # --- Also get per-student LATEST signals (unique student count) ---
    signals_res = supabase.table("signals").select("signal_type").eq("session_code", session_code).execute()
    signals = signals_res.data
    got_it = len([s for s in signals if s['signal_type'] == 'got_it'])
    sort_of = len([s for s in signals if s['signal_type'] == 'sort_of'])
    lost = len([s for s in signals if s['signal_type'] == 'lost'])

    questions_res = supabase.table("questions").select("id,is_addressed").eq("session_code", session_code).neq("status", "spam").execute()
    total_questions = len(questions_res.data)
    addressed = len([q for q in questions_res.data if q.get("is_addressed")])

    attendance_res = supabase.table("attendance").select("id", count="exact").eq("session_code", session_code).execute()

    return {
        "status": "session_ended",
        # Per-student latest signal (for pie chart / current state)
        "got_it": got_it,
        "sort_of": sort_of,
        "lost": lost,
        # Accumulated history (total signals across entire session)
        "hist_got_it": hist_got_it,
        "hist_sort_of": hist_sort_of,
        "hist_lost": hist_lost,
        "total_signals": hist_got_it + hist_sort_of + hist_lost,
        "total_students": attendance_res.count if attendance_res.count else (got_it + sort_of + lost),
        "total_questions": total_questions,
        "questions_addressed": addressed,
    }
# --- Mark Question Addressed ---
@router.post("/question/addressed")
async def mark_question_addressed(req: QuestionAddressedReq):
    supabase.table("questions").update({"is_addressed": req.is_addressed}).eq("id", req.question_id).execute()
    return {"status": "success", "is_addressed": req.is_addressed}

# --- Dismiss Question ---
class QuestionDismissReq(BaseModel):
    question_id: str

@router.post("/question/dismiss")
async def dismiss_question(req: QuestionDismissReq):
    supabase.table("questions").update({"status": "spam"}).eq("id", req.question_id).execute()
    return {"status": "success"}

# --- Generate AI Answer (Preview only) ---
@router.post("/doubt/generate")
async def generate_doubt_answer(req: DoubtAnswerReq):
    from ai_engine.assistant import generate_ai_answer
    try:
        res = supabase.table("questions").select("*").eq("id", req.question_id).execute()
        if not res.data:
            return {"error": "Question not found"}
        question_data = res.data[0]
        final_answer = generate_ai_answer(question_data.get("translated_text", "Explain this."), "Computer Science")
        return {"status": "success", "answer": final_answer}
    except Exception as e:
        return {"error": str(e)}

# --- Answer Doubt (AI or teacher) ---
@router.post("/doubt/answer")
async def answer_doubt(req: DoubtAnswerReq):
    from ai_engine.assistant import generate_ai_answer
    try:
        res = supabase.table("questions").select("*").eq("id", req.question_id).execute()
        if not res.data:
            return {"error": "Question not found"}
        question_data = res.data[0]
        final_answer = req.answer_text
        new_status = "answered_by_teacher"
        if not final_answer or str(final_answer).strip().lower() in ["null", "string", "none", ""]:
            final_answer = generate_ai_answer(question_data.get("translated_text", "Explain this."), "Computer Science")
            new_status = "answered_by_ai"
        supabase.table("questions").update({"status": new_status, "ai_response": final_answer}).eq("id", req.question_id).execute()
        return {"status": "success", "answer": final_answer}
    except Exception as e:
        return {"error": str(e)}

# --- Check Session ---
@router.get("/session/check/{session_code}")
async def check_session(session_code: str):
    res = supabase.table("sessions").select("*").eq("session_code", session_code).eq("is_active", True).execute()
    if not res.data:
        return {"valid": False}
    session = res.data[0]
    return {
        "valid": True,
        "class_name": session.get("class_name", ""),
        "subject": session.get("subject", ""),
        "topic": session.get("topic", ""),
        "subtopic": session.get("subtopic", ""),
        "current_subtopic_index": session.get("current_subtopic_index", 0),
    }

# --- Advance Subtopic (teacher moves to next subtopic) ---
@router.post("/session/advance-subtopic/{session_code}")
async def advance_subtopic(session_code: str):
    res = supabase.table("sessions").select("subtopic,current_subtopic_index").eq("session_code", session_code).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Session not found")

    session = res.data[0]
    subtopic_str = session.get("subtopic", "") or ""
    subtopics = [s.strip() for s in subtopic_str.split(",") if s.strip()] if subtopic_str else []
    current_idx = session.get("current_subtopic_index", 0) or 0

    if current_idx >= len(subtopics) - 1:
        return {"status": "already_at_last", "current_subtopic_index": current_idx, "total": len(subtopics)}

    new_idx = current_idx + 1
    supabase.table("sessions").update({"current_subtopic_index": new_idx}).eq("session_code", session_code).execute()

    return {
        "status": "success",
        "current_subtopic_index": new_idx,
        "current_subtopic": subtopics[new_idx] if new_idx < len(subtopics) else "",
        "total": len(subtopics),
    }