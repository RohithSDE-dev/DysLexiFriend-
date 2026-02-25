import requests
import json

BASE_URL = "http://localhost:8000/api"

# Test 1: Simplify Text
print("Testing text simplification...")
response = requests.post(f"{BASE_URL}/simplify-text", json={
    "text": "The photosynthesis process is extraordinarily complex.",
    "level": "grade_3"
})
print(json.dumps(response.json(), indent=2))

# Test 2: Generate Exercise
print("\nTesting exercise generation...")
response = requests.post(f"{BASE_URL}/generate-exercise", json={
    "difficulty": "easy",
    "topic": "animals"
})
print(json.dumps(response.json(), indent=2))

# Test 3: Save Progress
print("\nTesting progress save...")
response = requests.post(f"{BASE_URL}/save-progress", json={
    "student_id": "test_student_123",
    "session_data": {
        "words_read": 150,
        "accuracy": 85.5,
        "duration_minutes": 10,
        "topic": "animals"
    }
})
print(json.dumps(response.json(), indent=2))

# Test 4: Get Progress
print("\nTesting progress retrieval...")
response = requests.get(f"{BASE_URL}/get-progress/test_student_123")
print(json.dumps(response.json(), indent=2))
