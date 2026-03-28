from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from core.database import supabase
import random

# Create a router we will plug into main.py
router = APIRouter()

# --- Schemas ---
class SessionStartReq(BaseModel):
    session_id: str # The UUID of the pre-scheduled session

# --- Page 1: The Timetable ---
@router.get("/timetable/{teacher_id}")
async def get_timetable(teacher_id: str):
    """Fetches pre-scheduled classes for the teacher's home screen."""
    # In Supabase, these rows would have is_active=false and a null session_code initially
    res = supabase.table("sessions").select("*").eq("teacher_id", teacher_id).is_("session_code", "null").execute()
    return {"scheduled_sessions": res.data}

@router.post("/session/start")
async def start_scheduled_session(req: SessionStartReq):
    """Teacher clicks 'Start Session'. We generate the 4-digit code and make it live."""
    code = str(random.randint(1000, 9999))
    
    # Update the pre-scheduled session in Supabase to make it active
    res = supabase.table("sessions").update({
        "session_code": code,
        "is_active": True
    }).eq("id", req.session_id).execute()
    
    if not res.data:
        raise HTTPException(status_code=400, detail="Could not start session.")
        
    return {"status": "success", "session_code": code, "message": "Class is live!"}

# --- Page 2: Live Dashboard (The Main Hackathon Feature) ---
@router.get("/dashboard/{session_code}")
async def get_live_dashboard(session_code: str):
    """Fetches the live pulse of the classroom."""
    # 1. Get all signals for this session
    signals_res = supabase.table("signals").select("signal_type").eq("session_code", session_code).execute()
    signals = signals_res.data
    
    counts = {
        "got_it": len([s for s in signals if s['signal_type'] == 'got_it']),
        "sort_of": len([s for s in signals if s['signal_type'] == 'sort_of']),
        "lost": len([s for s in signals if s['signal_type'] == 'lost']),
    }
    
    # 2. Get unread doubts
    doubts_res = supabase.table("questions").select("*").eq("session_code", session_code).eq("status", "pending").execute()
    
    return {
        "session_code": session_code,
        "pulse": counts,
        "active_doubts": doubts_res.data
    }

# --- Page 3: Session History & n8n Summary ---
@router.get("/history/{teacher_id}")
async def get_session_history(teacher_id: str):
    """Fetches all past, completed sessions for this teacher."""
    # Fetch sessions where a code exists but it is no longer active
    res = supabase.table("sessions").select("*").eq("teacher_id", teacher_id).eq("is_active", False).not_.is_("session_code", "null").execute()
    return {"past_sessions": res.data}

@router.post("/session/end/{session_code}")
async def end_session(session_code: str):
    """Marks session as inactive and fires the n8n webhook for the summary."""
    # 1. Mark as inactive in DB
    supabase.table("sessions").update({"is_active": False}).eq("session_code", session_code).execute()
    
    # 2. Fire n8n Webhook (Harsh will set up the n8n side)
    # import requests
    # from core.config import settings
    # payload = {"session_code": session_code, "teacher_email": "teacher@school.com"}
    # requests.post(settings.N8N_WEBHOOK_URL, json=payload)
    
    return {"status": "session_ended", "message": "Summary report is being generated!"}
from schemas.pydantic_models import DoubtAnswerReq
from ai_engine.assistant import generate_ai_answer

@router.post("/doubt/answer")
async def answer_doubt(req: DoubtAnswerReq):
    try:
        print(f"--- 1. Fetching question ID: {req.question_id} ---")
        res = supabase.table("questions").select("*").eq("id", req.question_id).execute()
        
        if not res.data:
            return {"error": "Question not found in DB"}
            
        question_data = res.data[0]
        final_answer = req.answer_text
        new_status = "answered_by_teacher"
        
        # 🛡️ THE FIX: Check if answer is missing, empty, or Swagger junk text
        if not final_answer or str(final_answer).strip().lower() in ["null", "string", "none", ""]:
            print(f"--- 2. Calling Groq AI for: {question_data.get('translated_text')} ---")
            
            # Call Groq!
            final_answer = generate_ai_answer(question_data.get("translated_text", "Explain this."), "Computer Science")
            print(f"--- 3. Groq AI Response: {final_answer} ---")
            new_status = "answered_by_ai"
            
        print("--- 4. Updating Supabase ---")
        supabase.table("questions").update({
            "status": new_status,
            "ai_response": final_answer
        }).eq("id", req.question_id).execute()
        
        print(f"--- 5. Supabase Update Success! ---")
        return {"status": "success", "answer": final_answer}
        
    except Exception as e:
        print(f"!!! CRITICAL ERROR: {e} !!!")
        return {"error": str(e)}