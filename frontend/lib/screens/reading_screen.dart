import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/dyslexic_text.dart';
import '../widgets/voice_recorder.dart';
import '../services/ai_service.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  bool _isSimplified = false;
  bool _showSyllables = false;
  double _fontSize = 20.0;
  double _lineSpacing = 1.8;
  Color _backgroundColor = const Color(0xFFFFFBE6); // Cream
  Color _textColor = const Color(0xFF1A1A1A); // Dark gray

  String _sampleText = """
The quick brown fox jumps over the lazy dog. 
This is a sentence to demonstrate dyslexia-friendly reading.
Students can read comfortably with proper spacing and fonts.
""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 Read Together'),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Container(
        color: _backgroundColor,
        child: Column(
          children: [
            // Reading Controls
            _buildControlPanel(),
            
            // Main Reading Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: DyslexicText(
                  text: _isSimplified 
                      ? Provider.of<AIService>(context).simplifiedText ?? _sampleText
                      : _sampleText,
                  fontSize: _fontSize,
                  lineSpacing: _lineSpacing,
                  textColor: _textColor,
                  showSyllables: _showSyllables,
                ),
              ),
            ),
            
            // Voice Recorder
            VoiceRecorder(
              expectedText: _sampleText,
              onAnalysisComplete: (analysis) {
                _showAnalysisResults(analysis);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadNewText,
        icon: const Icon(Icons.refresh),
        label: const Text('New Text'),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.brightness_6,
                label: 'Simplify',
                isActive: _isSimplified,
                onTap: () {
                  setState(() {
                    _isSimplified = !_isSimplified;
                  });
                  if (_isSimplified) {
                    Provider.of<AIService>(context, listen: false)
                        .simplifyText(_sampleText, 'grade_3');
                  }
                },
              ),
              _buildControlButton(
                icon: Icons.text_fields,
                label: 'Syllables',
                isActive: _showSyllables,
                onTap: () {
                  setState(() {
                    _showSyllables = !_showSyllables;
                  });
                },
              ),
              _buildControlButton(
                icon: Icons.format_size,
                label: 'Size',
                onTap: _showFontSizeSlider,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.blue[700] : Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.blue[700] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeSlider() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Adjust Text Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: _fontSize,
              min: 14.0,
              max: 32.0,
              divisions: 9,
              label: _fontSize.round().toString(),
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),
            const SizedBox(height: 10),
            const Text('Adjust Line Spacing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: _lineSpacing,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              label: _lineSpacing.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _lineSpacing = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    // Color picker, font selection, etc.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reading Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Background Color'),
              trailing: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onTap: () {
                // Color picker
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _loadNewText() {
    // Load text from textbook, generate exercise, etc.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Reading Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload Textbook Page'),
              onTap: () {
                // Image picker + OCR
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: const Text('Generate Story'),
              onTap: () {
                Provider.of<AIService>(context, listen: false)
                    .generateExercise('easy', 'animals');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalysisResults(Map<String, dynamic> analysis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                '📊 Reading Analysis',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[700]),
              ),
              const SizedBox(height: 20),
              
              // Accuracy Score
              _buildScoreCard('Accuracy', analysis['accuracy'], Colors.green),
              
              // Stumbling Words
              if (analysis['stumbling_words'].isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Words to Practice:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...List.generate(
                  analysis['stumbling_words'].length,
                  (index) {
                    var word = analysis['stumbling_words'][index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: word['difficulty'] == 'high' ? Colors.red[100] : Colors.orange[100],
                          child: Text('${word['syllables']}'),
                        ),
                        title: Text(word['word'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        subtitle: Text('${word['syllables']} syllables'),
                      ),
                    );
                  },
                ),
              ],
              
              // Suggestions
              const SizedBox(height: 20),
              const Text('💡 Tips:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...List.generate(
                analysis['suggestions'].length,
                (index) => ListTile(
                  leading: const Icon(Icons.lightbulb, color: Colors.amber),
                  title: Text(analysis['suggestions'][index]),
                ),
              ),
              
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Got it!'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String label, double score, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(
              '${score.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color[700]),
            ),
          ],
        ),
      ),
    );
  }
}
