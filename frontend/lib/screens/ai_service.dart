import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class AIService extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000/api', // Change to your backend URL
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  String? _simplifiedText;
  List<Map<String, dynamic>> _syllableData = [];
  Map<String, dynamic> _progressData = {};
  Map<String, dynamic>? _currentExercise;

  String? get simplifiedText => _simplifiedText;
  List<Map<String, dynamic>> get syllableData => _syllableData;
  Map<String, dynamic> get progressData => _progressData;
  Map<String, dynamic>? get currentExercise => _currentExercise;

  Future<void> simplifyText(String text, String level) async {
    try {
      final response = await _dio.post('/simplify-text', data: {
        'text': text,
        'level': level,
      });

      if (response.data['success']) {
        _simplifiedText = response.data['simplified'];
        _syllableData = List<Map<String, dynamic>>.from(
          response.data['syllables'] ?? []
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error simplifying text: $e');
      rethrow;
    }
  }

  Future<void> breakIntoSyllables(String text) async {
    try {
      final response = await _dio.post('/simplify-text', data: {
        'text': text,
        'level': 'grade_3',
      });

      if (response.data['success']) {
        _syllableData = List<Map<String, dynamic>>.from(
          response.data['syllables'] ?? []
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error breaking syllables: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeSpeech(String audioPath, String expectedText) async {
    try {
      FormData formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioPath),
        'text': expectedText,
      });

      final response = await _dio.post('/analyze-speech', data: formData);

      if (response.data['success']) {
        return response.data['analysis'];
      }
      
      throw Exception('Analysis failed');
    } catch (e) {
      print('Error analyzing speech: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateExercise(String difficulty, String topic) async {
    try {
      final response = await _dio.post('/generate-exercise', data: {
        'difficulty': difficulty,
        'topic': topic,
      });

      if (response.data['success']) {
        _currentExercise = response.data['exercise'];
        notifyListeners();
        return _currentExercise!;
      }
      
      throw Exception('Failed to generate exercise');
    } catch (e) {
      print('Error generating exercise: $e');
      rethrow;
    }
  }

  Future<void> saveProgress(String studentId, Map<String, dynamic> sessionData) async {
    try {
      await _dio.post('/save-progress', data: {
        'student_id': studentId,
        'session_data': sessionData,
      });
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  Future<void> loadProgress(String studentId) async {
    try {
      final response = await _dio.get('/get-progress/$studentId');

      if (response.data['success']) {
        _progressData = response.data['progress'];
        notifyListeners();
      }
    } catch (e) {
      print('Error loading progress: $e');
    }
  }
}
