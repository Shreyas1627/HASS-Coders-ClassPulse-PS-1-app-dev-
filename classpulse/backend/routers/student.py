from fastapi import APIRouter, HTTPException
import uuid
from core.database import supabase
from schemas.pydantic_models import JoinReq, SignalReq, DoubtReq
from ai_engine.assistant import translate_indic_to_english, verify_and_classify_doubt

router = APIRouter()

@router.post("/join")
async def join_session(req: JoinReq):
    """Student joins using 4-digit code. We log attendance and return an anonymous ID."""
    
    # 1. Verify the session actually exists and is active
    res = supabase.table("sessions").select("id").eq("session_code", req.session_code).eq("is_active", True).execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Invalid or inactive session code.")
    
    # 2. Generate the anonymous UUID for the student
    student_uuid = str(uuid.uuid4())
    
    # 3. Log their actual Roll Number in the secret attendance table
    supabase.table("attendance").insert({
        "session_code": req.session_code,
        "student_uuid": student_uuid,
        "roll_number": req.roll_number
    }).execute()
    
    return {
        "status": "success", 
        "student_uuid": student_uuid, 
        "message": "Joined successfully! Waiting for teacher..."
    }

@router.post("/signal")
async def submit_signal(req: SignalReq):
    """Student taps a 3-color button. Updates their current status."""
    
    # Upsert: If they already voted, update it. If not, insert it.
    # Note: We added a UNIQUE(session_code, student_uuid) constraint in SQL for this!
    data = {
        "session_code": req.session_code,
        "student_uuid": req.student_uuid,
        "signal_type": req.signal,
        "updated_at": "now()"
    }
    
    # # If you are using milestones, include it. If not, ignore it for now.
    # if hasattr(req, 'milestone_id') and req.milestone_id:
    #     data["milestone_id"] = req.milestone_id

    supabase.table("signals").upsert(data, on_conflict="session_code, student_uuid").execute()
    
    return {"status": "success", "message": f"Signal updated to {req.signal}"}

@router.post("/doubt")
async def submit_doubt(req: DoubtReq):
    """Student submits a doubt. We run it through Sarvam & Groq before saving."""
    
    # 1. Translate via Sarvam AI (Hinglish -> English)
    english_text = translate_indic_to_english(req.text)
    
    # 2. Check for Spam/Jokes via Llama 3 (Groq)
    ai_check = verify_and_classify_doubt(english_text)
    
    # 3. Determine status
    status = "spam" if ai_check.get("is_spam") else "pending"
    
    # 4. 🛡️ BULLETPROOF PAYLOAD CONSTRUCTION
    db_payload = {
        "session_code": req.session_code,
        "student_uuid": req.student_uuid,
        "original_text": req.text,
        "translated_text": english_text,
        "status": status,
    }
    
    # ONLY add parent_id if it's an actual valid ID (fixes the "null" and "string" crash)
    if req.parent_id and req.parent_id not in ["null", "string"]:
        db_payload["parent_id"] = req.parent_id
        
    # 5. Save to Database
    supabase.table("questions").insert(db_payload).execute()
    
    if status == "spam":
        return {"status": "success", "message": "Doubt submitted."}
        
    return {"status": "success", "message": "Doubt submitted to teacher."}

# @router.post("/doubt")
# async def submit_doubt(req: DoubtReq):
#     """Student submits a doubt. We run it through Sarvam & Gemini before saving."""
    
#     # 1. Translate via Sarvam AI (Hinglish -> English)
#     english_text = translate_indic_to_english(req.text)
    
#     # 2. Check for Spam/Jokes via Gemini
#     ai_check = verify_and_classify_doubt(english_text)
    
#     # 3. Determine status
#     status = "spam" if ai_check["is_spam"] else "pending"
    
#     # 4. Save to Database
#     supabase.table("questions").insert({
#         "session_code": req.session_code,
#         "student_uuid": req.student_uuid,
#         "original_text": req.text,
#         "translated_text": english_text,
#         "status": status,
#         "parent_id": req.parent_id # For the "Re-ask" thread feature
#     }).execute()
    
#     if status == "spam":
#         # We tell the student it was submitted so they don't try again, 
#         # but the teacher will never see it! (Hackathon magic)
#         return {"status": "success", "message": "Doubt submitted."}
        
#     return {"status": "success", "message": "Doubt submitted to teacher."}

@router.get("/poll/status/{session_code}")
async def check_poll_status(session_code: str):
    """Dummy endpoint to stop the frontend from throwing 404 errors."""
    return {"status": "none", "active_poll": False}

@router.get("/my-doubts/{session_code}/{student_uuid}")
async def get_my_doubts(session_code: str, student_uuid: str):
    """Fetches the student's doubts and any AI/Teacher responses."""
    
    # Fetch questions for this specific student in this session
    res = supabase.table("questions").select("*").eq("session_code", session_code).eq("student_uuid", student_uuid).execute()
    
    # Filter to only show doubts that have a response
    answered_doubts = [d for d in res.data if d.get("ai_response") or d.get("status") == "answered_by_teacher"]
    
    return {"answered_doubts": answered_doubts}