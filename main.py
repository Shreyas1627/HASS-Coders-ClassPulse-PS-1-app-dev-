import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from routers import teacher, student
import uuid
from fastapi.responses import RedirectResponse

app = FastAPI(title="SyncClass Core")

# 1. ALLOW CORS (Crucial for Sonu's App to talk to your API)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],    
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 2. MOUNT HARSH'S WEBPAGE (Crucial for Offline Fallback)
# Create a folder called 'webpage' in your root directory. Harsh will put his HTML/JS here.
# import os
# if not os.path.exists("webpage"):
#     os.makedirs("webpage")
app.mount("/student_web", StaticFiles(directory="webpage", html=True), name="student_web")


app.include_router(teacher.router, prefix="/api/teacher", tags=["Teacher App"])
app.include_router(student.router, prefix="/api/student", tags=["Student Webpage"])
# --- In-Memory DB (Swap to Supabase/SQLite later) ---
sessions = {}

# --- Pydantic Schemas ---
class JoinReq(BaseModel): session_code: str; roll_number: str
class SignalReq(BaseModel): session_code: str; student_uuid: str; milestone_id: str; signal: str
class DoubtReq(BaseModel): session_code: str; student_uuid: str; sub_topic: str; text: str

# --- API ENDPOINTS ---
# @app.get("/")
# def redirect_to_app():
#     """If someone just types the IP address, auto-redirect them to the app!"""
#     return RedirectResponse(url="/webpage/index.html")


@app.post("/api/join")
async def join_session(req: JoinReq):
    # Log roll number for attendance (secretly), return anonymous UUID
    student_uuid = str(uuid.uuid4())
    return {"status": "success", "student_uuid": student_uuid, "current_milestone": "1_intro"}

@app.post("/api/signal")
async def submit_signal(req: SignalReq):
    # Logic: Validate UUID, update DB, handle "freeze" cooldown
    return {"status": "success"}

@app.post("/api/doubt")
async def submit_doubt(req: DoubtReq):
    # Logic: Pass to Gemini for Spam Check, then save to DB
    return {"status": "submitted"}

@app.get("/api/poll/status/{session_code}")
async def check_poll(session_code: str):
    # Harsh's webpage will ping this every 3 seconds to see if teacher launched a quiz
    return {"active_poll": False, "poll_data": None}

if __name__ == "__main__":
    # Run this locally for the offline demo
    uvicorn.run(app, host="0.0.0.0", port=8000)