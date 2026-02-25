import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  String _selectedDifficulty = 'easy';
  String _selectedTopic = 'animals';
  Map<String, dynamic>? _currentExercise;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showingAnswer = false;

  final List<Map<String, String>> _topics = [
    {'id': 'animals', 'name': 'Animals 🐶', 'emoji': '🐶'},
    {'id': 'space', 'name': 'Space 🚀', 'emoji': '🚀'},
    {'id': 'food', 'name': 'Food 🍕', 'emoji': '🍕'},
    {'id': 'sports', 'name': 'Sports ⚽', 'emoji': '⚽'},
    {'id': 'nature', 'name': 'Nature 🌳', 'emoji': '🌳'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Reading Games'),
        backgroundColor: Colors.green[600],
        elevation: 0,
      ),
      body: _currentExercise == null
          ? _buildExerciseSelector()
          : _buildExercisePlayer(),
    );
  }

  Widget _buildExerciseSelector() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Choose Your Adventure!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        
        // Difficulty Selector
        const Text('Difficulty Level:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            _buildDifficultyChip('easy', 'Easy 😊', Colors.green),
            _buildDifficultyChip('medium', 'Medium 🤔', Colors.orange),
            _buildDifficultyChip('hard', 'Hard 🔥', Colors.red),
          ],
        ),
        
        const SizedBox(height: 30),
        
        // Topic Selector
        const Text('Choose a Topic:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: _topics.length,
          itemBuilder: (context, index) {
            final topic = _topics[index];
            final isSelected = _selectedTopic == topic['id'];
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTopic = topic['id']!;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(topic['emoji']!, style: const TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text(
                      topic['name']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 30),
        
        // Start Button
        ElevatedButton.icon(
          onPressed: _loadExercise,
          icon: const Icon(Icons.play_arrow, size: 28),
          label: const Text('Start Reading!', style: TextStyle(fontSize: 20)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyChip(String difficulty, String label, Color color) {
    final isSelected = _selectedDifficulty == difficulty;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDifficulty = difficulty;
        });
      },
      selectedColor: color.withOpacity(0.3),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? color[700] : Colors.grey[700],
      ),
    );
  }

  Future<void> _loadExercise() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final aiService = Provider.of<AIService>(context, listen: false);
      final exercise = await aiService.generateExercise(_selectedDifficulty, _selectedTopic);
      
      Navigator.pop(context); // Close loading dialog
      
      setState(() {
        _currentExercise = exercise;
        _currentQuestionIndex = 0;
        _score = 0;
        _showingAnswer = false;
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate exercise. Please try again.')),
      );
    }
  }

  Widget _buildExercisePlayer() {
    if (_currentExercise == null) return const SizedBox.shrink();

    final story = _currentExercise!['story'] ?? '';
    final questions = _currentExercise!['questions'] ?? [];

    if (_currentQuestionIndex >= questions.length) {
      return _buildCompletionScreen();
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Story Section
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book, color: Colors.blue),
                    const SizedBox(width: 10),
                    const Text('Story', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                SelectableText(
                  story,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.8,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Question Section
        _buildQuestionCard(questions[_currentQuestionIndex]),
        
        const SizedBox(height: 20),
        
        // Progress Indicator
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / questions.length,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
        ),
        const SizedBox(height: 10),
        Text(
          'Question ${_currentQuestionIndex + 1} of ${questions.length}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    String type = question['type'] ?? 'mcq';
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '❓ Question',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question['question'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            if (type == 'mcq')
              ..._buildMCQOptions(question)
            else if (type == 'truefalse')
              ..._buildTrueFalseOptions(question)
            else if (type == 'fillblank')
              _buildFillBlankInput(question),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMCQOptions(Map<String, dynamic> question) {
    List options = question['options'] ?? [];
    String correctAnswer = question['answer'] ?? '';
    
    return options.map<Widget>((option) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ElevatedButton(
          onPressed: _showingAnswer ? null : () => _checkAnswer(option, correctAnswer),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: _showingAnswer && option == correctAnswer
                ? Colors.green[100]
                : Colors.grey[200],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _showingAnswer && option == correctAnswer
                    ? Colors.green
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            option,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.left,
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTrueFalseOptions(Map<String, dynamic> question) {
    bool correctAnswer = question['answer'] ?? true;
    
    return [
      _buildTrueFalseButton('True ✓', true, correctAnswer),
      const SizedBox(height: 12),
      _buildTrueFalseButton('False ✗', false, correctAnswer),
    ];
  }

  Widget _buildTrueFalseButton(String label, bool value, bool correctAnswer) {
    return ElevatedButton(
      onPressed: _showingAnswer ? null : () => _checkAnswer(value, correctAnswer),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        backgroundColor: _showingAnswer && value == correctAnswer
            ? Colors.green[100]
            : Colors.grey[200],
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _showingAnswer && value == correctAnswer
                ? Colors.green
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }

  Widget _buildFillBlankInput(Map<String, dynamic> question) {
    TextEditingController controller = TextEditingController();
    
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _showingAnswer 
              ? null 
              : () => _checkAnswer(controller.text.trim(), question['answer']),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Submit Answer', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  void _checkAnswer(dynamic userAnswer, dynamic correctAnswer) {
    bool isCorrect = userAnswer.toString().toLowerCase() == correctAnswer.toString().toLowerCase();
    
    setState(() {
      _showingAnswer = true;
      if (isCorrect) {
        _score++;
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isCorrect ? '🎉 Correct!' : '❌ Not quite!',
          style: TextStyle(
            color: isCorrect ? Colors.green[700] : Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCorrect)
              Text(
                'The correct answer is: $correctAnswer',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 10),
            Text(
              isCorrect 
                  ? 'Great job! Keep it up! 🌟' 
                  : 'Don\'t worry, you\'ll get it next time! 💪',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentQuestionIndex++;
                _showingAnswer = false;
              });
            },
            child: const Text('Next Question'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final totalQuestions = _currentExercise!['questions'].length;
    final percentage = (_score / totalQuestions * 100).toInt();
    final funFact = _currentExercise!['fun_fact'] ?? 'Great job!';
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎊', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text(
              'Exercise Complete!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            // Score Card
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[300]!, Colors.blue[300]!],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '$_score / $totalQuestions',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$percentage% Correct',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Text(
                funFact,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentExercise = null;
                      });
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadExercise,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
