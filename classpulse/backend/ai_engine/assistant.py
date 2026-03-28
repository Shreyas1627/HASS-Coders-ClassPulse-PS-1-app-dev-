import google.generativeai as genai
import requests
import os
from core.config import settings
from groq import Groq

# Initialize Groq Client
client = Groq(api_key=os.getenv("GROQ_API_KEY"))
# Using Llama 3 8B for lightning-fast latency
MODEL_NAME = "llama-3.3-70b-versatile"

def verify_and_classify_doubt(text: str) -> dict:
    """Uses Groq Llama 3 to check if a doubt is spam/joke."""
    prompt = f"""
    You are a strict classroom assistant. Read this student's doubt.
    If it is a joke, gibberish, abusive, or highly irrelevant, reply ONLY with the exact word 'SPAM'.
    If it is a genuine academic question, reply ONLY with the exact word 'VALID'.
    Student Doubt: "{text}"
    """
    try:
        completion = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[{"role": "user", "content": prompt}],
            temperature=0,
            max_tokens=10,
        )
        result = completion.choices[0].message.content.strip().upper()
        return {"is_spam": "SPAM" in result}
    except Exception as e:
        print(f"Groq Error: {e}")
        return {"is_spam": False}

def generate_ai_answer(question_text: str, subject: str) -> str:
    """Generates an explanation on behalf of the teacher."""
    prompt = f"""
    You are an expert teacher explaining a concept in a {subject} class.
    A student asked: "{question_text}"
    Provide a clear, encouraging, and concise answer (under 3 sentences).
    """
    try:
        completion = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.5,
            max_tokens=150,
        )
        return completion.choices[0].message.content.strip()
    except Exception as e:
        return "I'm having trouble analyzing this right now. Please ask the teacher!"

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