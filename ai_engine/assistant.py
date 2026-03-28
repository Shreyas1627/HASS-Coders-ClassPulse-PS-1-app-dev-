import google.generativeai as genai
import requests
from core.config import settings

# Configure Gemini
genai.configure(api_key=settings.GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-1.5-flash')

def verify_and_classify_doubt(text: str) -> dict:
    """Uses Gemini to check if a doubt is spam/joke or valid."""
    prompt = f"""
    You are a strict classroom assistant. Read this student's doubt.
    If it is a joke, gibberish, abusive, or highly irrelevant, reply ONLY with 'SPAM'.
    If it is a genuine academic question, reply ONLY with 'VALID'.
    Student Doubt: "{text}"
    """
    try:
        response = model.generate_content(prompt)
        result = response.text.strip().upper()
        return {"is_spam": result == "SPAM"}
    except Exception as e:
        print(f"Gemini Error: {e}")
        return {"is_spam": False} # Default to letting it through if AI fails

def generate_ai_answer(question_text: str, subject: str) -> str:
    """Generates an explanation on behalf of the teacher."""
    prompt = f"""
    You are an expert teacher explaining a concept in a {subject} class.
    A student asked: "{question_text}"
    Provide a clear, encouraging, and concise answer (under 3 sentences).
    """
    try:
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        return "I'm having trouble analyzing this right now. Please ask the teacher directly!"

def translate_indic_to_english(text: str) -> str:
    """Uses Sarvam AI to translate Hinglish/Hindi to clean English."""
    url = "https://api.sarvam.ai/translate"
    headers = {
        "api-subscription-key": settings.SARVAM_API_KEY, 
        "Content-Type": "application/json"
    }
    payload = {
        "input": [text],
        "source_language_code": "hi-IN",
        "target_language_code": "en-IN",
        "speaker_gender": "Male",
        "mode": "formal",
        "model": "sarvam-translate"
    }
    try:
        response = requests.post(url, json=payload, headers=headers)
        if response.status_code == 200:
            return response.json()["translations"][0]
        return text # Fallback to original if translation fails
    except Exception as e:
        print(f"Sarvam Error: {e}")
        return text