import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import 'dart:async';

class VoiceRecorder extends StatefulWidget {
  final String expectedText;
  final Function(Map<String, dynamic>) onAnalysisComplete;

  const VoiceRecorder({
    super.key,
    required this.expectedText,
    required this.onAnalysisComplete,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isAnalyzing = false;
  String? _audioPath;
  
  late AnimationController _animationController;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final path = '/temp/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });

        // Start timer
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });

        _animationController.repeat();
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });

      _animationController.stop();

      if (path != null) {
        // Auto-analyze after recording
        _analyzeRecording();
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_audioPath == null) return;

    try {
      setState(() {
        _isPlaying = true;
      });

      await _audioPlayer.play(DeviceFileSource(_audioPath!));
      
      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false;
        });
      });
    } catch (e) {
      print('Error playing recording: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopPlaying() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _analyzeRecording() async {
    if (_audioPath == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      final analysis = await aiService.analyzeSpeech(_audioPath!, widget.expectedText);
      
      setState(() {
        _isAnalyzing = false;
      });

      widget.onAnalysisComplete(analysis);
    } catch (e) {
      print('Error analyzing speech: $e');
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analysis failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAnalyzing)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('🧠 AI is analyzing your reading...', style: TextStyle(fontSize: 16)),
              ],
            )
          else if (_audioPath != null)
            _buildPlaybackControls()
          else
            _buildRecordingControls(),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Column(
      children: [
        if (_isRecording) ...[
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 80 + (_animationController.value * 20),
                height: 80 + (_animationController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.3),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            _formatDuration(_recordingSeconds),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
        ],
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isRecording)
              _buildActionButton(
                icon: Icons.mic,
                label: 'Start Reading',
                color: Colors.blue,
                onPressed: _startRecording,
              )
            else
              _buildActionButton(
                icon: Icons.stop,
                label: 'Stop',
                color: Colors.red,
                onPressed: _stopRecording,
              ),
          ],
        ),
        
        if (!_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '🎤 Tap to read the text aloud',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: _isPlaying ? Icons.stop : Icons.play_arrow,
              label: _isPlaying ? 'Stop' : 'Play',
              color: Colors.green,
              onPressed: _isPlaying ? _stopPlaying : _playRecording,
            ),
            _buildActionButton(
              icon: Icons.refresh,
              label: 'Re-record',
              color: Colors.orange,
              onPressed: () {
                setState(() {
                  _audioPath = null;
                });
              },
            ),
            _buildActionButton(
              icon: Icons.analytics,
              label: 'Analyze',
              color: Colors.purple,
              onPressed: _analyzeRecording,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
