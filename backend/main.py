from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from services.gemini_service import GeminiService
from services.speech_analysis import SpeechAnalyzer
from services.progress_tracker import ProgressTracker
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="DysLexiFriend API")

# CORS for Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

gemini = GeminiService(os.getenv("GEMINI_API_KEY"))
speech_analyzer = SpeechAnalyzer()
progress_tracker = ProgressTracker()

@app.get("/")
async def root():
    return {"message": "DysLexiFriend API v1.0", "status": "active"}

@app.post("/api/analyze-speech")
async def analyze_speech(audio: UploadFile = File(...), text: str = ""):
    """Analyze student's reading audio for stumbling patterns"""
    try:
        # Save temporary audio file
        audio_path = f"temp_{audio.filename}"
        with open(audio_path, "wb") as f:
            f.write(await audio.read())
        
        # Analyze speech
        analysis = speech_analyzer.analyze_reading(audio_path, text)
        
        # Clean up
        os.remove(audio_path)
        
        return {
            "success": True,
            "analysis": analysis,
            "difficulty_score": analysis["difficulty_score"],
            "stumbling_words": analysis["stumbling_words"],
            "suggestions": analysis["suggestions"]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/simplify-text")
async def simplify_text(data: dict):
    """Use Gemini to simplify complex text for dyslexic readers"""
    try:
        original_text = data.get("text", "")
        reading_level = data.get("level", "grade_3")  # grade_3, grade_5, grade_8
        
        simplified = gemini.simplify_for_dyslexia(original_text, reading_level)
        syllables = gemini.break_into_syllables(original_text)
        
        return {
            "success": True,
            "original": original_text,
            "simplified": simplified,
            "syllables": syllables,
            "reading_time_estimate": len(original_text.split()) * 0.6  # seconds
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/generate-exercise")
async def generate_exercise(data: dict):
    """Generate personalized reading exercise"""
    try:
        difficulty = data.get("difficulty", "easy")
        topic = data.get("topic", "animals")
        
        exercise = gemini.generate_reading_exercise(difficulty, topic)
        
        return {
            "success": True,
            "exercise": exercise
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/save-progress")
async def save_progress(data: dict):
    """Save student reading progress"""
    try:
        student_id = data.get("student_id")
        session_data = data.get("session_data")
        
        progress_tracker.save_session(student_id, session_data)
        
        return {"success": True, "message": "Progress saved"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/get-progress/{student_id}")
async def get_progress(student_id: str):
    """Get student's reading progress dashboard"""
    try:
        progress = progress_tracker.get_student_progress(student_id)
        return {
            "success": True,
            "progress": progress
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
