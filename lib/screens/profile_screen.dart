import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/login_screen.dart';
import '../profile/edit_portfolio_screen.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  Future<DocumentSnapshot<Map<String, dynamic>>> _getProfile() {
    return FirebaseFirestore.instance.collection('users').doc(userId).get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _getProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: Text('Could not load your profile.')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: Text('Profile not found.')),
          );
        }

        final data = snapshot.data!.data()!;

        final String name = data['name'] ?? 'Student';
        final String college = data['college'] ?? '';
        final String course = data['course'] ?? 'Student';
        final String year = data['year'] ?? '';
        final String bio = data['bio'] ?? '';

        final List<String> canTeach = List<String>.from(data['canTeach'] ?? []);

        final List<String> wantsToLearn = List<String>.from(
          data['wantsToLearn'] ?? [],
        );

        final int xp = (data['xp'] as num?)?.toInt() ?? 0;

        final List<int> levelThresholds = [0, 100, 250, 450, 700, 1000];

        final int level = levelThresholds
            .where((threshold) => xp >= threshold)
            .length;

        final List<String> badges = List<String>.from(data['badges'] ?? []);

        final int currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;

        final int longestStreak = (data['longestStreak'] as num?)?.toInt() ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile editing will be added soon.'),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Log out?'),
                      content: const Text(
                        'Are you sure you want to log out of SkillSwap?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, false);
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext, true);
                          },
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout != true || !context.mounted) {
                    return;
                  }

                  await FirebaseAuth.instance.signOut();

                  if (!context.mounted) return;

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 3),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 58,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$course${year.isNotEmpty ? ' • $year' : ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.lightText,
                          fontSize: 15,
                        ),
                      ),
                      if (college.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          college,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.lightText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.darkText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // XP, level and badges
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '$xp',
                        label: 'XP',
                        icon: Icons.bolt_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: '$level',
                        label: 'Level',
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value: '${badges.length}',
                        label: 'Badges',
                        icon: Icons.emoji_events_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // XP progress
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.background, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: AppTheme.primary,
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Your Learning Journey',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ),
                          Text(
                            'Level $level',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Builder(
                        builder: (context) {
                          final currentThreshold = levelThresholds[level - 1];

                          final nextThreshold = level < levelThresholds.length
                              ? levelThresholds[level]
                              : levelThresholds.last;

                          final progress = level < levelThresholds.length
                              ? ((xp - currentThreshold) /
                                        (nextThreshold - currentThreshold))
                                    .clamp(0.0, 1.0)
                              : 1.0;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 12,
                                  backgroundColor: Colors.white,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppTheme.primary,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$xp XP',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkText,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      level < levelThresholds.length
                                          ? '${nextThreshold - xp} XP to Level ${level + 1}'
                                          : 'Maximum level reached!',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.lightText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Learning streak
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0D9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFE98A28),
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Learning Streak',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$currentStreak ${currentStreak == 1 ? 'day' : 'days'} in a row!',
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.lightText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Longest streak: $longestStreak ${longestStreak == 1 ? 'day' : 'days'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Skills I can teach
                _SectionCard(
                  title: 'Skills I Can Teach',
                  icon: Icons.school_rounded,
                  skills: canTeach,
                  emptyText: 'No teaching skills selected.',
                ),

                const SizedBox(height: 16),

                // Skills I want to learn
                _SectionCard(
                  title: 'Skills I Want to Learn',
                  icon: Icons.auto_awesome_rounded,
                  skills: wantsToLearn,
                  emptyText: 'No learning skills selected.',
                ),

                const SizedBox(height: 16),

                // Portfolio and links
                _PortfolioLinksCard(userId: userId),

                const SizedBox(height: 16),

                // Badges
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: AppTheme.secondary,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Badges',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (badges.isEmpty)
                        const Text(
                          'Complete quests and exchanges to earn badges!',
                          style: TextStyle(color: AppTheme.lightText),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: badges.map((badge) {
                            return Chip(
                              avatar: const Icon(
                                Icons.verified_rounded,
                                size: 18,
                              ),
                              label: Text(badge),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PortfolioLinksCard extends StatelessWidget {
  final String userId;

  const _PortfolioLinksCard({required this.userId});

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This link is not valid.')));
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
    }
  }

  Future<void> _editLinks(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditPortfolioScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};

        final githubUrl = data['githubUrl'] as String? ?? '';
        final portfolioUrl = data['portfolioUrl'] as String? ?? '';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.work_outline_rounded, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Text(
                    'Portfolio & Links',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.background,
                  child: Icon(Icons.code_rounded, color: AppTheme.primary),
                ),
                title: const Text('GitHub'),
                subtitle: Text(
                  githubUrl.isEmpty ? 'Add your GitHub profile' : githubUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(
                  githubUrl.isEmpty
                      ? Icons.edit_rounded
                      : Icons.open_in_new_rounded,
                ),
                onTap: () async {
                  if (githubUrl.isEmpty) {
                    await _editLinks(context);
                  } else {
                    await _openLink(context, githubUrl);
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.background,
                  child: Icon(Icons.language_rounded, color: AppTheme.primary),
                ),
                title: const Text('Portfolio Website'),
                subtitle: Text(
                  portfolioUrl.isEmpty
                      ? 'Add your portfolio website'
                      : portfolioUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(
                  portfolioUrl.isEmpty
                      ? Icons.edit_rounded
                      : Icons.open_in_new_rounded,
                ),
                onTap: () async {
                  if (portfolioUrl.isEmpty) {
                    await _editLinks(context);
                  } else {
                    await _openLink(context, portfolioUrl);
                  }
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _editLinks(context),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit Links'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.lightText),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> skills;
  final String emptyText;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.skills,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (skills.isEmpty)
            Text(emptyText, style: const TextStyle(color: AppTheme.lightText))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
