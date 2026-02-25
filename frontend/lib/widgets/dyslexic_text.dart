import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';

class DyslexicText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double lineSpacing;
  final Color textColor;
  final bool showSyllables;

  const DyslexicText({
    super.key,
    required this.text,
    this.fontSize = 20.0,
    this.lineSpacing = 1.8,
    this.textColor = const Color(0xFF1A1A1A),
    this.showSyllables = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showSyllables) {
      return _buildSyllableView(context);
    }
    return _buildNormalView();
  }

  Widget _buildNormalView() {
    return SelectableText(
      text,
      style: TextStyle(
        fontSize: fontSize,
        height: lineSpacing,
        color: textColor,
        fontFamily: 'OpenDyslexic', // Fallback to Comic Sans if not available
        letterSpacing: 1.2, // Wider letter spacing for dyslexia
        wordSpacing: 3.0, // More word spacing
      ),
      textAlign: TextAlign.left,
    );
  }

  Widget _buildSyllableView(BuildContext context) {
    final aiService = Provider.of<AIService>(context);
    final syllableData = aiService.syllableData;

    if (syllableData.isEmpty) {
      // Request syllable breakdown
      aiService.breakIntoSyllables(text);
      return const Center(child: CircularProgressIndicator());
    }

    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: syllableData.map((wordData) {
        return _buildSyllableCard(wordData);
      }).toList(),
    );
  }

  Widget _buildSyllableCard(Map<String, dynamic> wordData) {
    String word = wordData['word'] ?? '';
    String syllables = wordData['syllables'] ?? word;
    int syllableCount = wordData['count'] ?? 1;

    // Color coding by syllable count
    Color cardColor;
    if (syllableCount == 1) {
      cardColor = Colors.green[100]!;
    } else if (syllableCount == 2) {
      cardColor = Colors.blue[100]!;
    } else if (syllableCount == 3) {
      cardColor = Colors.orange[100]!;
    } else {
      cardColor = Colors.red[100]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            syllables,
            style: TextStyle(
              fontSize: fontSize * 0.9,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 2.0,
            ),
          ),
          if (syllableCount > 1)
            Text(
              '$syllableCount parts',
              style: TextStyle(
                fontSize: fontSize * 0.5,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}

// Alternative: Highlight difficult words inline
class HighlightedDyslexicText extends StatelessWidget {
  final String text;
  final List<String> difficultWords;
  final double fontSize;

  const HighlightedDyslexicText({
    super.key,
    required this.text,
    this.difficultWords = const [],
    this.fontSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    List<TextSpan> spans = [];
    List<String> words = text.split(' ');

    for (String word in words) {
      bool isDifficult = difficultWords.contains(word.toLowerCase().replaceAll(RegExp(r'[^\w]'), ''));
      
      spans.add(
        TextSpan(
          text: '$word ',
          style: TextStyle(
            fontSize: fontSize,
            backgroundColor: isDifficult ? Colors.yellow[200] : Colors.transparent,
            fontWeight: isDifficult ? FontWeight.bold : FontWeight.normal,
            color: isDifficult ? Colors.red[700] : const Color(0xFF1A1A1A),
            height: 1.8,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: const TextStyle(
          fontFamily: 'OpenDyslexic',
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
