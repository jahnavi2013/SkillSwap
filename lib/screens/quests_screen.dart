import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/badge_service.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quests & Rewards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic XP header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: AppTheme.secondary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child:
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseAuth.instance.currentUser == null
                              ? null
                              : FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .snapshots(),
                          builder: (context, snapshot) {
                            final data = snapshot.data?.data();
                            final xp = (data?['xp'] as num?)?.toInt() ?? 0;

                            const levelThresholds = [
                              0,
                              100,
                              250,
                              450,
                              700,
                              1000,
                            ];

                            var level = 1;

                            for (var i = 0; i < levelThresholds.length; i++) {
                              if (xp >= levelThresholds[i]) {
                                level = i + 1;
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.hasError
                                      ? 'XP unavailable'
                                      : '$xp XP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Level $level • Skill Explorer',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Streak section (currently display-only)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text('🔥', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '7 Day Streak!',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Keep learning every day to extend your streak.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.lightText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              "🎯 Today's Quests",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),

            const SizedBox(height: 12),

            const DailyLearningQuestCard(),

            const SizedBox(height: 8),

            const QuestCard(
              title: 'Complete a Python Quiz',
              description: 'Answer 5 questions',
              xp: 50,
              icon: Icons.code_rounded,
            ),

            const QuestCard(
              title: 'Explore a New Skill',
              description: 'View 3 student profiles',
              xp: 30,
              icon: Icons.explore_rounded,
            ),

            const QuestCard(
              title: 'Start a Skill Exchange',
              description: 'Send your first request today',
              xp: 75,
              icon: Icons.swap_horiz_rounded,
            ),

            const SizedBox(height: 26),

            const Text(
              '🏅 Your Badges',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  BadgeItem(emoji: '🔥', title: '7 Day', subtitle: 'Streak'),
                  BadgeItem(emoji: '🤝', title: 'First', subtitle: 'Swap'),
                  BadgeItem(emoji: '⭐', title: '100', subtitle: 'XP'),
                  BadgeItem(emoji: '🚀', title: 'Level', subtitle: '5'),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              '🎲 Mystery Quest',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Text('❓', style: TextStyle(fontSize: 42)),
                  const SizedBox(height: 10),
                  const Text(
                    'Something unexpected awaits...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Complete a surprise challenge and earn bonus XP.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.darkText),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mystery quest unlocked! 🎉'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkText,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Reveal Quest',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Daily Learning Quest: award 20 XP once per day.
class DailyLearningQuestCard extends StatefulWidget {
  const DailyLearningQuestCard({super.key});

  @override
  State<DailyLearningQuestCard> createState() => _DailyLearningQuestCardState();
}

class _DailyLearningQuestCardState extends State<DailyLearningQuestCard> {
  bool _loading = true;
  bool _claiming = false;
  bool _completed = false;
  String? _errorMessage;

  String get _todayKey {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${year}-${month}-${day}_daily_learning';
  }

  @override
  void initState() {
    super.initState();
    _loadCompletion();
  }

  Future<void> _loadCompletion() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Please sign in to claim this quest.';
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyQuestCompletions')
          .doc(_todayKey)
          .get();

      if (mounted) {
        setState(() {
          _completed = doc.exists;
          _loading = false;
          _errorMessage = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Could not load quest status. Please try again.';
        });
      }
    }
  }

  Future<void> _claimQuest() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in to claim this quest.');
      return;
    }

    setState(() {
      _claiming = true;
      _errorMessage = null;
    });

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);

    final completionRef = userRef
        .collection('dailyQuestCompletions')
        .doc(_todayKey);

    try {
      final wasAlreadyCompleted = await firestore.runTransaction<bool>((
        tx,
      ) async {
        // Check the daily completion record first.
        final completionSnapshot = await tx.get(completionRef);

        if (completionSnapshot.exists) {
          return true;
        }

        // Read the user's current XP.
        // Read the user's current XP and badges.
        final userSnapshot = await tx.get(userRef);
        final currentData = userSnapshot.data() ?? <String, dynamic>{};
        final currentXp = currentData['xp'];
        final xp = currentXp is num ? currentXp.toInt() : 0;

        final badges = List<String>.from(currentData['badges'] ?? <String>[]);

        // Award the first-quest badge.
        if (!badges.contains(BadgeService.firstSteps)) {
          badges.add(BadgeService.firstSteps);
        }

        // Award the XP badge if this reward takes the user to 100 XP.
        final newXp = xp + 20;
        if (newXp >= 100 && !badges.contains(BadgeService.xpCollector)) {
          badges.add(BadgeService.xpCollector);
        }

        // Save XP and badges together.
        if (userSnapshot.exists) {
          tx.update(userRef, {'xp': newXp, 'badges': badges});
        } else {
          tx.set(userRef, {
            'xp': newXp,
            'badges': badges,
          }, SetOptions(merge: true));
        }

        // Record completion to prevent duplicate daily rewards.
        tx.set(completionRef, {
          'questId': 'daily_learning',
          'date': _todayKey.substring(0, 10),
          'xpAwarded': 20,
          'completedAt': FieldValue.serverTimestamp(),
        });

        return false;
      });

      if (!mounted) return;

      setState(() {
        _completed = true;
        _claiming = false;
      });

      _showMessage(
        wasAlreadyCompleted
            ? "You have already claimed today's quest."
            : 'Daily quest completed! +20 XP 🎉',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _claiming = false;
        _errorMessage =
            'Could not claim the quest. Check your connection and try again.';
      });

      _showMessage('Could not claim the quest. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Learning Quest',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Spend a little time learning a skill today.',
                      style: TextStyle(fontSize: 13, color: AppTheme.lightText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+20 XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_loading || _claiming || _completed)
                  ? null
                  : _claimQuest,
              icon: _claiming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _completed
                          ? Icons.check_circle_rounded
                          : Icons.stars_rounded,
                    ),
              label: Text(
                _loading
                    ? 'Checking quest...'
                    : _claiming
                    ? 'Claiming...'
                    : _completed
                    ? 'Completed today'
                    : 'Mark complete & claim 20 XP',
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// Display-only quest cards for now.
class QuestCard extends StatelessWidget {
  final String title;
  final String description;
  final int xp;
  final IconData icon;

  const QuestCard({
    super.key,
    required this.title,
    required this.description,
    required this.xp,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.lightText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+$xp XP',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Display-only badges for now.
class BadgeItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const BadgeItem({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 30)),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppTheme.lightText),
        ),
      ],
    );
  }
}
