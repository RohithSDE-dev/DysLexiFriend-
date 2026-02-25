import google.generativeai as genai
from typing import List, Dict
import json

class GeminiService:
    def __init__(self, api_key: str):
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-1.5-flash')
    
    def simplify_for_dyslexia(self, text: str, level: str) -> str:
        """Simplify text using Gemini - dyslexia-friendly version"""
        prompt = f"""
You are an expert reading specialist for dyslexic students.

Original text: "{text}"

Rewrite this text for a {level} reading level with these rules:
1. Use short, simple sentences (max 10 words)
2. Avoid complex words - use common alternatives
3. Break long words into smaller chunks with hyphens
4. Use active voice only
5. Add line breaks every 2 sentences
6. Replace difficult words with easier synonyms

Return ONLY the simplified text, nothing else.
"""
        
        response = self.model.generate_content(prompt)
        return response.text.strip()
    
    def break_into_syllables(self, text: str) -> List[Dict]:
        """Break words into syllables with AI assistance"""
        prompt = f"""
Break these words into syllables with • separators:
{text}

Format: word: syl•la•bles

Example:
difficulty: dif•fi•cul•ty
reading: read•ing
"""
        
        response = self.model.generate_content(prompt)
        
        # Parse response
        syllable_data = []
        for line in response.text.strip().split('\n'):
            if ':' in line:
                word, syllables = line.split(':', 1)
                syllable_data.append({
                    "word": word.strip(),
                    "syllables": syllables.strip(),
                    "count": syllables.count('•') + 1
                })
        
        return syllable_data
    
    def generate_reading_exercise(self, difficulty: str, topic: str) -> Dict:
        """Generate gamified reading exercise"""
        difficulty_map = {
            "easy": "Grade 1-2 (50-100 words)",
            "medium": "Grade 3-4 (100-150 words)",
            "hard": "Grade 5-6 (150-200 words)"
        }
        
        prompt = f"""
Create a fun, dyslexia-friendly reading exercise:

Topic: {topic}
Difficulty: {difficulty_map[difficulty]}

Requirements:
1. Write a short, engaging story
2. Use dyslexia-friendly formatting:
   - Short sentences (max 10 words)
   - Simple, common words
   - Active voice
   - Clear paragraph breaks
3. After the story, create 3 interactive questions:
   - 1 multiple choice
   - 1 true/false
   - 1 fill-in-the-blank

Return JSON format:
{{
  "story": "text here",
  "questions": [
    {{"type": "mcq", "question": "", "options": [], "answer": ""}},
    {{"type": "truefalse", "question": "", "answer": true}},
    {{"type": "fillblank", "question": "", "answer": ""}}
  ],
  "fun_fact": "encouraging message"
}}
"""
        
        response = self.model.generate_content(prompt)
        
        # Extract JSON from response
        text = response.text.strip()
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0]
        
        return json.loads(text)
    
    def generate_encouragement(self, performance_score: float) -> str:
        """Generate personalized encouragement message"""
        if performance_score >= 80:
            messages = [
                "🌟 Amazing! You're becoming a reading superstar!",
                "🎉 Fantastic work! Keep up the great reading!",
                "⭐ You're crushing it! Your hard work is paying off!"
            ]
        elif performance_score >= 60:
            messages = [
                "💪 Good effort! You're making progress!",
                "📚 Nice job! Practice makes perfect!",
                "🎯 You're getting better every day!"
            ]
        else:
            messages = [
                "🌱 Great start! Every expert was once a beginner!",
                "💫 Keep trying! You're learning something new!",
                "🚀 Don't give up! You're on the right path!"
            ]
        
        import random
        return random.choice(messages)
