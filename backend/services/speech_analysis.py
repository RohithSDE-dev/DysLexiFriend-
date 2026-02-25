import speech_recognition as sr
from pydub import AudioSegment
import syllables
import re
from typing import Dict, List

class SpeechAnalyzer:
    def __init__(self):
        self.recognizer = sr.Recognizer()
    
    def analyze_reading(self, audio_path: str, expected_text: str) -> Dict:
        """Analyze student's reading for stumbling patterns"""
        
        # Convert to WAV if needed
        if not audio_path.endswith('.wav'):
            audio = AudioSegment.from_file(audio_path)
            wav_path = audio_path.rsplit('.', 1)[0] + '.wav'
            audio.export(wav_path, format='wav')
            audio_path = wav_path
        
        # Transcribe audio
        with sr.AudioFile(audio_path) as source:
            audio_data = self.recognizer.record(source)
            try:
                spoken_text = self.recognizer.recognize_google(audio_data)
            except:
                spoken_text = ""
        
        # Analyze differences
        analysis = self._compare_texts(expected_text, spoken_text)
        
        return analysis
    
    def _compare_texts(self, expected: str, spoken: str) -> Dict:
        """Compare expected vs spoken text to find stumbling points"""
        
        expected_words = expected.lower().split()
        spoken_words = spoken.lower().split()
        
        stumbling_words = []
        difficulty_score = 0
        
        # Find missing/mispronounced words
        for word in expected_words:
            if word not in spoken_words:
                syllable_count = syllables.estimate(word)
                stumbling_words.append({
                    "word": word,
                    "syllables": syllable_count,
                    "difficulty": "high" if syllable_count > 3 else "medium"
                })
                difficulty_score += syllable_count
        
        # Calculate accuracy
        accuracy = (1 - len(stumbling_words) / max(len(expected_words), 1)) * 100
        
        # Generate suggestions
        suggestions = self._generate_suggestions(stumbling_words)
        
        return {
            "expected_text": expected,
            "spoken_text": spoken,
            "accuracy": round(accuracy, 2),
            "stumbling_words": stumbling_words,
            "difficulty_score": difficulty_score,
            "suggestions": suggestions
        }
    
    def _generate_suggestions(self, stumbling_words: List[Dict]) -> List[str]:
        """Generate helpful suggestions based on mistakes"""
        suggestions = []
        
        if not stumbling_words:
            suggestions.append("Perfect reading! Try a harder level!")
            return suggestions
        
        # Analyze patterns
        complex_words = [w for w in stumbling_words if w["syllables"] > 3]
        
        if complex_words:
            suggestions.append(f"Practice breaking long words into syllables")
            suggestions.append(f"Try reading these words slowly: {', '.join([w['word'] for w in complex_words[:3]])}")
        
        suggestions.append("Take a deep breath between sentences")
        suggestions.append("Use your finger to track each word")
        
        return suggestions
