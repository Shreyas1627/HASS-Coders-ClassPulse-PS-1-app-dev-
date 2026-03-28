from pydantic import BaseModel
from typing import Optional

# --- Teacher App Schemas ---
class SessionCreate(BaseModel):
    teacher_id: str
    subject: str

class MilestoneCreate(BaseModel):
    session_code: str
    title: str

class DoubtAnswerReq(BaseModel):
    question_id: str
    answer_text: Optional[str] = None # If None, trigger AI Answer

# --- Student Webpage Schemas ---
class JoinReq(BaseModel):
    session_code: str
    roll_number: str

class SignalReq(BaseModel):
    session_code: str
    student_uuid: str
    signal: str 
    milestone_id: Optional[str] = None # Forgiving

class DoubtReq(BaseModel):
    session_code: str
    student_uuid: str
    text: str
    milestone_id: Optional[str] = None # Forgiving
    parent_id: Optional[str] = None # Forgiving