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
    milestone_id: str
    signal: str # 'got_it', 'sort_of', 'lost'

class DoubtReq(BaseModel):
    session_code: str
    student_uuid: str
    milestone_id: str
    text: str
    parent_id: Optional[str] = None # Used if this is a "Re-ask" follow-up