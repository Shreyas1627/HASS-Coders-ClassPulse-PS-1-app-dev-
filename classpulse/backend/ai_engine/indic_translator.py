import os
import requests
from dotenv import load_dotenv

load_dotenv()
SARVAM_API_KEY = os.getenv("SARVAM_API_KEY")

def process_doubt_with_sarvam(student_text: str) -> dict:
    # 1. Call Sarvam AI Translation API (assuming Hindi to English for this example)
    url = "https://api.sarvam.ai/translate"
    headers = {"api-subscription-key": SARVAM_API_KEY, "Content-Type": "application/json"}
    payload = {
        "input": [student_text],
        "source_language_code": "hi-IN",
        "target_language_code": "en-IN",
        "speaker_gender": "Male",
        "mode": "formal",
        "model": "sarvam-translate"
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        translated_text = response.json()["translations"][0]
        
        # 2. Add your basic rule-based spam check or intent logic here
        is_spam = False
        if len(translated_text) < 3 or "haha" in translated_text.lower():
            is_spam = True
            
        return {
            "original": student_text,
            "translated": translated_text,
            "is_spam": is_spam,
            "tag": "Urgent" if "?" in translated_text else "General"
        }
    except Exception as e:
        print(f"Sarvam API Error: {e}")
        return {"original": student_text, "translated": student_text, "is_spam": False, "tag": "General"}