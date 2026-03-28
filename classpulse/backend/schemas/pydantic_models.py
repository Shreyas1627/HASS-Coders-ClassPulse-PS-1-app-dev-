from pydantic import BaseModel
from typing import Optional

# --- Teacher App Schemas ---
class SessionCreate(BaseModel):
    teacher_id: str
    subject: str

class SessionCreateReq(BaseModel):
    teacher_id: str = "default_teacher"
    class_name: str
    subject: str
    topic: str
    subtopic: Optional[str] = None
    scheduled_at: Optional[str] = None

class SessionStartReq(BaseModel):
    session_id: str  # The UUID of the pre-scheduled session

class MilestoneCreate(BaseModel):
    session_code: str
    title: str

class DoubtAnswerReq(BaseModel):
    question_id: str
    answer_text: Optional[str] = None  # If None, trigger AI Answer

class QuestionAddressedReq(BaseModel):
    question_id: str
    is_addressed: bool = True

# --- Student Webpage Schemas ---
class JoinReq(BaseModel):
    session_code: str
    roll_number: str

class SignalReq(BaseModel):
    session_code: str
    student_uuid: str
    signal: str 
    milestone_id: Optional[str] = None

class DoubtReq(BaseModel):
    session_code: str
    student_uuid: str
    text: str
    milestone_id: Optional[str] = None
    parent_id: Optional[str] = None

class QuestionUpvoteReq(BaseModel):
    question_id: str