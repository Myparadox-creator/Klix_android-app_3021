
import uuid
import logging
from typing import Dict, List, Optional
from pydantic import BaseModel
from llm_client import get_client, Message, LLMClient
from config import get_config

logger = logging.getLogger(__name__)

class InterviewSession(BaseModel):
    session_id: str
    user_id: str
    role: str
    topic: str
    difficulty: str
    messages: List[Message] = []
    status: str = "active" # active, completed
    feedback: Optional[str] = None

# In-memory storage for prototype
sessions: Dict[str, InterviewSession] = {}

class StartInterviewRequest(BaseModel):
    user_id: str
    role: str
    topic: str
    difficulty: str = "Medium"

class ChatRequest(BaseModel):
    session_id: str
    message: str

class InterviewResponse(BaseModel):
    message: str
    session_id: str
    status: str

class FeedbackResponse(BaseModel):
    feedback: str

async def start_interview(request: StartInterviewRequest) -> InterviewResponse:
    session_id = str(uuid.uuid4())
    
    # Construct initial system prompt
    system_prompt = (
        f"You are an expert interviewer for the role of {request.role}. "
        f"The topic is {request.topic} and the difficulty level is {request.difficulty}. "
        "Your goal is to conduct a realistic technical interview. "
        "Start by welcoming the candidate and asking the first relevant question. "
        "Keep your responses concise and professional. Do not provide answers, just ask questions. "
        "If the candidate is stuck, provide a small hint but do not give the solution. "
        "After 3-4 exchanges, you will be asked to provide feedback."
    )

    messages = [Message(role="system", content=system_prompt)]
    
    # Initialize session
    session = InterviewSession(
        session_id=session_id,
        user_id=request.user_id,
        role=request.role,
        topic=request.topic,
        difficulty=request.difficulty,
        messages=messages
    )
    sessions[session_id] = session

    # Get first question from LLM
    llm_client = get_client()
    
    # We trigger the first message generation
    # We can simulate an empty user message to kickstart or just ask LLM to start
    # Let's add a user instruction to start
    start_msg = Message(role="user", content="Please start the interview.")
    messages.append(start_msg)
    
    try:
        response = await llm_client.chat(messages, stream=False)
        assistant_msg = Message(role="assistant", content=response.content)
        session.messages.append(assistant_msg)
        
        return InterviewResponse(
            message=response.content,
            session_id=session_id,
            status="active"
        )
    except Exception as e:
        logger.error(f"Error starting interview: {e}")
        raise e

async def process_chat(request: ChatRequest) -> InterviewResponse:
    session_id = request.session_id
    if session_id not in sessions:
        raise ValueError("Session not found")
    
    session = sessions[session_id]
    if session.status != "active":
         return InterviewResponse(
            message="This interview has ended. Please request feedback.",
            session_id=session_id,
            status=session.status
        )

    # Add user message
    user_msg = Message(role="user", content=request.message)
    session.messages.append(user_msg)

    llm_client = get_client()
    
    try:
        # Check if we should end the interview (simple logic: after 10 messages total = 5 turns)
        # Exclude system message
        if len(session.messages) > 10:
             session.status = "completed"
             return InterviewResponse(
                message="Thank you for your time. The interview is now complete. You can view your feedback.",
                session_id=session_id,
                status="completed"
            )

        response = await llm_client.chat(session.messages, stream=False)
        assistant_msg = Message(role="assistant", content=response.content)
        session.messages.append(assistant_msg)
        
        return InterviewResponse(
            message=response.content,
            session_id=session_id,
            status="active"
        )
    except Exception as e:
        logger.error(f"Error processing chat: {e}")
        raise e

async def generate_feedback(session_id: str) -> FeedbackResponse:
    if session_id not in sessions:
        raise ValueError("Session not found")
    
    session = sessions[session_id]
    if session.feedback:
        return FeedbackResponse(feedback=session.feedback)

    llm_client = get_client()
    
    # Create a new context for feedback generation
    feedback_prompt = (
        "Based on the following interview transcript, provide detailed feedback to the candidate. "
        "Highlight strengths, weaknesses, and areas for improvement. "
        "Be constructive and encouraging.\n\n"
        "transcript:\n"
    )
    
    transcript = ""
    for msg in session.messages:
        if msg.role != "system":
            transcript += f"{msg.role.upper()}: {msg.content}\n"
            
    feedback_messages = [
        Message(role="system", content="You are an interview coach."),
        Message(role="user", content=feedback_prompt + transcript)
    ]

    try:
        response = await llm_client.chat(feedback_messages, stream=False)
        session.feedback = response.content
        session.status = "completed" # Ensure it's marked completed
        return FeedbackResponse(feedback=session.feedback)
    except Exception as e:
        logger.error(f"Error generating feedback: {e}")
        raise e
