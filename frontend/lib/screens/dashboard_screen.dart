import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load progress data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AIService>(context, listen: false).loadProgress('student_123');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 My Progress'),
        backgroundColor: Colors.purple[600],
        elevation: 0,
      ),
      body: Consumer<AIService>(
        builder: (context, aiService, child) {
          final progress = aiService.progressData;

          if (progress.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats Cards
              _buildStatsGrid(progress),
              
              const SizedBox(height: 20),
              
              // Streak & Badges
              _buildStreakCard(progress),
              
              const SizedBox(height: 20),
              
              // Progress Chart
              _buildProgressChart(progress),
              
              const SizedBox(height: 20),
              
              // Badges
              _buildBadgesSection(progress),
              
              const SizedBox(height: 20),
              
              // Recent Sessions
              _buildRecentSessions(progress),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> progress) {
    final stats = progress['statistics'] ?? {};
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          '📚 Words Read',
          '${progress['total_words_read'] ?? 0}',
          Colors.blue,
          Icons.book,
        ),
        _buildStatCard(
          '⏱️ Time Spent',
          '${progress['total_time_minutes'] ?? 0}m',
          Colors.green,
          Icons.timer,
        ),
        _buildStatCard(
          '🎯 Accuracy',
          '${stats['avg_accuracy']?.toStringAsFixed(1) ?? '0'}%',
          Colors.orange,
          Icons.trending_up,
        ),
        _buildStatCard(
          '📈 Improvement',
          '+${stats['improvement_percent']?.toStringAsFixed(1) ?? '0'}%',
          Colors.purple,
          Icons.show_chart,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color[700],
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(Map<String, dynamic> progress) {
    int streak = progress['streak_days'] ?? 0;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[300]!, Colors.red[300]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 48)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak Day Streak!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Keep reading daily to maintain your streak',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart(Map<String, dynamic> progress) {
    List sessions = progress['sessions'] ?? [];
    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Take last 7 sessions
    List recentSessions = sessions.length > 7 
        ? sessions.sublist(sessions.length - 7) 
        : sessions;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Accuracy Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < recentSessions.length) {
                            return Text('Day ${index + 1}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        recentSessions.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          (recentSessions[index]['accuracy'] ?? 0).toDouble(),
                        ),
                      ),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(Map<String, dynamic> progress) {
    List<String> badges = progress['statistics']?['badges_earned'] ?? [];
    
    if (badges.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.emoji_events, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                'No badges yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const Text('Keep reading to earn your first badge'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏆 Badges Earned',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: badges.map((badge) => _buildBadge(badge)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[300]!, Colors.orange[300]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        badge,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRecentSessions(Map<String, dynamic> progress) {
    List sessions = progress['sessions'] ?? [];
    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Take last 5 sessions
    List recentSessions = sessions.length > 5 
        ? sessions.sublist(sessions.length - 5).reversed.toList()
        : sessions.reversed.toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📅 Recent Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recentSessions.map((session) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getAccuracyColor(session['accuracy'] ?? 0),
                  child: Text(
                    '${session['accuracy']?.toInt() ?? 0}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text('${session['words_read'] ?? 0} words'),
                subtitle: Text(session['topic'] ?? 'General Reading'),
                trailing: Text(
                  _formatTimestamp(session['timestamp']),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Colors.green[400]!;
    if (accuracy >= 60) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }
}
