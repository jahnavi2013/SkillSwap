import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SkillSwap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            const Text(
              'Hi, Student! 👋',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Ready to learn something new today?',
              style: TextStyle(fontSize: 15, color: AppTheme.lightText),
            ),

            const SizedBox(height: 20),

            // XP Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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

                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1,240 XP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Level 5 • Skill Explorer',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Daily Quest
            const SectionTitle(title: '🎯 Daily Quest'),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      color: AppTheme.darkText,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete a Python quiz',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '5 questions • +50 XP',
                          style: TextStyle(color: AppTheme.lightText),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: AppTheme.lightText,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Skill Matches
            const SectionTitle(title: '🤝 Skill Matches'),

            const SizedBox(height: 12),

            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  SkillCard(
                    name: 'Alex',
                    skill: 'Python',
                    icon: Icons.code_rounded,
                  ),
                  SkillCard(
                    name: 'Sam',
                    skill: 'UI Design',
                    icon: Icons.design_services_rounded,
                  ),
                  SkillCard(
                    name: 'Maya',
                    skill: 'Video Editing',
                    icon: Icons.video_library_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Trending Skills
            const SectionTitle(title: '🔥 Trending Skills'),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                SkillChip(text: 'Python'),
                SkillChip(text: 'UI/UX'),
                SkillChip(text: 'Video Editing'),
                SkillChip(text: 'Public Speaking'),
                SkillChip(text: 'Web Development'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.darkText,
      ),
    );
  }
}

class SkillCard extends StatelessWidget {
  final String name;
  final String skill;
  final IconData icon;

  const SkillCard({
    super.key,
    required this.name,
    required this.skill,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.background,
                child: Icon(icon, color: AppTheme.primary),
              ),

              const SizedBox(width: 10),

              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),

          const Spacer(),

          const Text(
            'Can teach',
            style: TextStyle(fontSize: 12, color: AppTheme.lightText),
          ),

          const SizedBox(height: 3),

          Text(
            skill,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class SkillChip extends StatelessWidget {
  final String text;

  const SkillChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.darkText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
