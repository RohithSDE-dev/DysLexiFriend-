from datetime import datetime
from typing import Dict, List
import json
import os

class ProgressTracker:
    def __init__(self, data_dir: str = "data"):
        self.data_dir = data_dir
        os.makedirs(data_dir, exist_ok=True)
    
    def save_session(self, student_id: str, session_data: Dict):
        """Save a reading session"""
        
        file_path = f"{self.data_dir}/{student_id}.json"
        
        # Load existing data
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                data = json.load(f)
        else:
            data = {
                "student_id": student_id,
                "sessions": [],
                "total_words_read": 0,
                "total_time_minutes": 0,
                "streak_days": 0
            }
        
        # Add new session
        session_data["timestamp"] = datetime.now().isoformat()
        data["sessions"].append(session_data)
        
        # Update totals
        data["total_words_read"] += session_data.get("words_read", 0)
        data["total_time_minutes"] += session_data.get("duration_minutes", 0)
        
        # Calculate streak
        data["streak_days"] = self._calculate_streak(data["sessions"])
        
        # Save
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
    
    def get_student_progress(self, student_id: str) -> Dict:
        """Get comprehensive progress report"""
        
        file_path = f"{self.data_dir}/{student_id}.json"
        
        if not os.path.exists(file_path):
            return {"error": "No data found for student"}
        
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        # Calculate statistics
        sessions = data["sessions"]
        
        if not sessions:
            return data
        
        recent_sessions = sessions[-7:]  # Last 7 sessions
        
        avg_accuracy = sum(s.get("accuracy", 0) for s in recent_sessions) / len(recent_sessions)
        improvement = self._calculate_improvement(sessions)
        
        return {
            **data,
            "statistics": {
                "avg_accuracy": round(avg_accuracy, 2),
                "improvement_percent": round(improvement, 2),
                "sessions_completed": len(sessions),
                "favorite_topic": self._find_favorite_topic(sessions),
                "badges_earned": self._calculate_badges(data)
            }
        }
    
    def _calculate_streak(self, sessions: List[Dict]) -> int:
        """Calculate consecutive days of reading"""
        if not sessions:
            return 0
        
        dates = [datetime.fromisoformat(s["timestamp"]).date() for s in sessions]
        dates = sorted(set(dates), reverse=True)
        
        streak = 1
        for i in range(len(dates) - 1):
            diff = (dates[i] - dates[i+1]).days
            if diff == 1:
                streak += 1
            else:
                break
        
        return streak
    
    def _calculate_improvement(self, sessions: List[Dict]) -> float:
        """Calculate improvement over time"""
        if len(sessions) < 2:
            return 0.0
        
        first_5 = sessions[:5]
        last_5 = sessions[-5:]
        
        avg_first = sum(s.get("accuracy", 0) for s in first_5) / len(first_5)
        avg_last = sum(s.get("accuracy", 0) for s in last_5) / len(last_5)
        
        return avg_last - avg_first
    
    def _find_favorite_topic(self, sessions: List[Dict]) -> str:
        """Find most practiced topic"""
        topics = [s.get("topic", "general") for s in sessions]
        if not topics:
            return "general"
        return max(set(topics), key=topics.count)
    
    def _calculate_badges(self, data: Dict) -> List[str]:
        """Award badges based on achievements"""
        badges = []
        
        total_words = data.get("total_words_read", 0)
        streak = data.get("streak_days", 0)
        sessions_count = len(data.get("sessions", []))
        
        if total_words >= 1000:
            badges.append("📚 Bookworm")
        if total_words >= 5000:
            badges.append("🏆 Reading Champion")
        
        if streak >= 7:
            badges.append("🔥 Week Warrior")
        if streak >= 30:
            badges.append("⭐ Monthly Master")
        
        if sessions_count >= 10:
            badges.append("🎯 Consistent Learner")
        if sessions_count >= 50:
            badges.append("💎 Dedication Diamond")
        
        return badges
