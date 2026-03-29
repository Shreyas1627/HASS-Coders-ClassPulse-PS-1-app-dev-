from fastapi import APIRouter, HTTPException, Query
import uuid
import math
from core.database import supabase
from schemas.pydantic_models import JoinReq, SignalReq, DoubtReq, QuestionUpvoteReq
from ai_engine.assistant import translate_indic_to_english, verify_and_classify_doubt

router = APIRouter()

@router.post("/join")
async def join_session(req: JoinReq):
    res = supabase.table("sessions").select("id,subject,class_name,topic,subtopic,current_subtopic_index,latitude,longitude").eq("session_code", req.session_code).eq("is_active", True).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Invalid or inactive session code.")

    session = res.data[0]
    
    # Geofencing check (100 meter limit)
    t_lat, t_lng = session.get("latitude"), session.get("longitude")
    if t_lat is not None and t_lng is not None:
        if req.latitude is None or req.longitude is None:
            raise HTTPException(status_code=403, detail="Location permission is required to join this session.")
            
        # Haversine formula
        R = 6371000 # Radius of Earth in meters
        phi1 = math.radians(t_lat)
        phi2 = math.radians(req.latitude)
        delta_phi = math.radians(req.latitude - t_lat)
        delta_lambda = math.radians(req.longitude - t_lng)
        
        a = math.sin(delta_phi/2.0)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda/2.0)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        distance = R * c
        
        if distance > 100:
            raise HTTPException(status_code=403, detail=f"You are too far from the classroom ({int(distance)}m). Maximum allowed is 100m.")

    student_uuid = str(uuid.uuid4())

    supabase.table("attendance").insert({
        "session_code": req.session_code,
        "student_uuid": student_uuid,
        "roll_number": req.roll_number,
        "warnings": 0,
        "is_blocked": False
    }).execute()

    return {
        "status": "success",
        "student_uuid": student_uuid,
        "subject": session.get("subject", ""),
        "class_name": session.get("class_name", ""),
        "topic": session.get("topic", ""),
        "subtopic": session.get("subtopic", ""),
        "current_subtopic_index": session.get("current_subtopic_index", 0),
    }

@router.post("/signal")
async def submit_signal(req: SignalReq):
    from datetime import datetime, timezone
    now_iso = datetime.now(timezone.utc).isoformat()

    # Upsert current signal (live dashboard shows latest per student)
    data = {
        "session_code": req.session_code,
        "student_uuid": req.student_uuid,
        "signal_type": req.signal,
        "updated_at": now_iso,
    }
    supabase.table("signals").upsert(data, on_conflict="session_code, student_uuid").execute()

    # Also log to history table (accumulates all signals for summary/analytics)
    supabase.table("signal_history").insert({
        "session_code": req.session_code,
        "student_uuid": req.student_uuid,
        "signal_type": req.signal,
    }).execute()

    return {"status": "success", "signal": req.signal}

@router.post("/doubt")
async def submit_doubt(req: DoubtReq):
    english_text = translate_indic_to_english(req.text)
    ai_check = verify_and_classify_doubt(english_text)
    status = "spam" if ai_check.get("is_spam") else "pending"

    db_payload = {
        "session_code": req.session_code,
        "student_uuid": req.student_uuid,
        "original_text": req.text,
        "translated_text": english_text,
        "status": status,
    }
    if req.subtopic:
        db_payload["subtopic"] = req.subtopic
    if req.parent_id and req.parent_id not in ["null", "string"]:
        db_payload["parent_id"] = req.parent_id

    supabase.table("questions").insert(db_payload).execute()

    return {"status": "success", "is_spam": status == "spam"}

@router.get("/poll/status/{session_code}")
async def check_poll_status(session_code: str, student_uuid: str = Query(None)):
    res = supabase.table("sessions").select("is_active,subtopic,current_subtopic_index").eq("session_code", session_code).execute()
    if res.data and not res.data[0].get("is_active", True):
        return {"status": "closed"}
        
    if student_uuid:
        att = supabase.table("attendance").select("is_blocked").eq("session_code", session_code).eq("student_uuid", student_uuid).execute()
        if att.data and att.data[0].get("is_blocked"):
            return {"status": "blocked"}
            
    session = res.data[0] if res.data else {}
    return {
        "status": "active",
        "subtopic": session.get("subtopic", ""),
        "current_subtopic_index": session.get("current_subtopic_index", 0),
    }

from schemas.pydantic_models import TabSwitchReq
@router.post("/tab-switch")
async def register_tab_switch(req: TabSwitchReq):
    att = supabase.table("attendance").select("warnings, is_blocked").eq("session_code", req.session_code).eq("student_uuid", req.student_uuid).execute()
    if not att.data:
        return {"status": "error", "detail": "Student not found"}
        
    warnings = att.data[0].get("warnings", 0)
    is_blocked = att.data[0].get("is_blocked", False)
    
    if not is_blocked:
        warnings += 1
        if warnings >= 2:
            is_blocked = True
        supabase.table("attendance").update({
            "warnings": warnings,
            "is_blocked": is_blocked
        }).eq("session_code", req.session_code).eq("student_uuid", req.student_uuid).execute()
        
    return {"status": "success", "warnings": warnings, "is_blocked": is_blocked}

@router.get("/questions/{session_code}")
async def get_questions(session_code: str):
    res = supabase.table("questions").select("id,original_text,translated_text,status,ai_response,upvotes,is_addressed,created_at").eq("session_code", session_code).neq("status", "spam").order("upvotes", desc=True).execute()
    return {"questions": res.data}

@router.post("/question/upvote")
async def upvote_question(req: QuestionUpvoteReq):
    res = supabase.table("questions").select("upvotes").eq("id", req.question_id).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Question not found")
    current = res.data[0].get("upvotes", 0) or 0
    supabase.table("questions").update({"upvotes": current + 1}).eq("id", req.question_id).execute()
    return {"status": "success", "upvotes": current + 1}

@router.get("/my-doubts/{session_code}/{student_uuid}")
async def get_my_doubts(session_code: str, student_uuid: str):
    res = supabase.table("questions").select("*").eq("session_code", session_code).eq("student_uuid", student_uuid).execute()
    answered = [d for d in res.data if d.get("ai_response") or d.get("status") == "answered_by_teacher"]
    return {"answered_doubts": answered}

@router.get("/session/info/{session_code}")
async def get_session_info(session_code: str):
    res = supabase.table("sessions").select("*").eq("session_code", session_code).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Session not found")
    session = res.data[0]
    return {
        "session_code": session_code,
        "subject": session.get("subject", ""),
        "class_name": session.get("class_name", ""),
        "topic": session.get("topic", ""),
        "is_active": session.get("is_active", False),
    }

# --- Active sessions any student can join ---
@router.get("/sessions/active")
async def get_active_sessions_for_students():
    res = supabase.table("sessions").select("*").eq("is_active", True).order("created_at", desc=True).execute()
    return {"sessions": res.data}

# --- Student's past session history (by roll number) ---
@router.get("/history/{roll_number}")
async def get_student_history(roll_number: str):
    # Find all sessions this student attended
    att_res = supabase.table("attendance").select("session_code,student_uuid").eq("roll_number", roll_number).execute()
    if not att_res.data:
        return {"sessions": []}

    result = []
    for att in att_res.data:
        sc = att["session_code"]
        su = att["student_uuid"]

        # Get session info
        sess_res = supabase.table("sessions").select("subject,topic,created_at").eq("session_code", sc).execute()
        if not sess_res.data:
            continue
        sess = sess_res.data[0]

        # Get this student's signal
        sig_res = supabase.table("signals").select("signal_type").eq("session_code", sc).eq("student_uuid", su).execute()
        signal = "none"
        if sig_res.data:
            raw = sig_res.data[0]["signal_type"]
            signal = "understood" if raw == "got_it" else ("maybe" if raw == "sort_of" else "not_understood")

        # Get student's doubts
        doubt_res = supabase.table("questions").select("original_text").eq("session_code", sc).eq("student_uuid", su).neq("status", "spam").execute()
        doubt_text = doubt_res.data[0]["original_text"] if doubt_res.data else None

        # Format date
        date_str = ""
        try:
            from datetime import datetime
            dt = datetime.fromisoformat(sess["created_at"].replace("+00", "+00:00"))
            date_str = dt.strftime("%d %b")
        except:
            pass

        result.append({
            "subject": sess.get("subject", ""),
            "topic": sess.get("topic", ""),
            "date": date_str,
            "signal": signal,
            "doubt": doubt_text,
        })

    return {"sessions": result}