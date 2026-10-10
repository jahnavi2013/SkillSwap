import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/main_navigation.dart';
import '../theme/app_theme.dart';

class SelectSkillsScreen extends StatefulWidget {
  const SelectSkillsScreen({super.key});

  @override
  State<SelectSkillsScreen> createState() => _SelectSkillsScreenState();
}

class _SelectSkillsScreenState extends State<SelectSkillsScreen> {
  final List<String> _skills = [
    'Python',
    'Flutter',
    'Java',
    'C++',
    'Web Development',
    'UI/UX Design',
    'Graphic Design',
    'Video Editing',
    'Public Speaking',
    'Content Writing',
    'Photography',
    'Digital Marketing',
    'Data Science',
    'Machine Learning',
    'Cybersecurity',
  ];

  final Set<String> _canTeach = {};
  final Set<String> _wantToLearn = {};

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSkills();
  }

  // ------------------------------------------------------------
  // LOAD EXISTING SKILLS
  // ------------------------------------------------------------

  Future<void> _loadExistingSkills() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final data = doc.data() ?? {};

      final savedCanTeach = List<String>.from(data['canTeach'] ?? []);

      final savedWantsToLearn = List<String>.from(data['wantsToLearn'] ?? []);

      if (!mounted) return;

      setState(() {
        _canTeach
          ..clear()
          ..addAll(savedCanTeach);

        _wantToLearn
          ..clear()
          ..addAll(savedWantsToLearn);

        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(e.message ?? 'Could not load your existing skills.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Could not load your existing skills.');
    }
  }

  // ------------------------------------------------------------
  // TOGGLE TEACHING SKILL
  // ------------------------------------------------------------

  void _toggleTeach(String skill) {
    setState(() {
      if (_canTeach.contains(skill)) {
        _canTeach.remove(skill);
      } else {
        _canTeach.add(skill);

        // A skill cannot be both taught and learned.
        _wantToLearn.remove(skill);
      }
    });
  }

  // ------------------------------------------------------------
  // TOGGLE LEARNING SKILL
  // ------------------------------------------------------------

  void _toggleLearn(String skill) {
    setState(() {
      if (_wantToLearn.contains(skill)) {
        _wantToLearn.remove(skill);
      } else {
        _wantToLearn.add(skill);

        // A skill cannot be both learned and taught.
        _canTeach.remove(skill);
      }
    });
  }

  // ------------------------------------------------------------
  // SAVE SKILLS
  // ------------------------------------------------------------

  Future<void> _continue() async {
    if (_canTeach.isEmpty || _wantToLearn.isEmpty) {
      _showMessage(
        'Choose at least one skill to teach and one skill to learn.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('No logged-in user found. Please login again.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'canTeach': _canTeach.toList(),
        'wantsToLearn': _wantToLearn.toList(),
        'skillsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainNavigation(userId: user.uid)),
        (route) => false,
      );
    } on FirebaseException catch (e) {
      _showMessage(e.message ?? 'Could not save your skills.');
    } catch (e) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------
  // SKILL CHIP
  // ------------------------------------------------------------

  Widget _skillChip({
    required String skill,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              size: 18,
              color: selected ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              skill,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION HEADER
  // ------------------------------------------------------------

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppTheme.lightText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Skills')),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Build your skill profile 🧩',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Tell us what you can teach and what you would like to learn.',
                      style: TextStyle(fontSize: 15, color: AppTheme.lightText),
                    ),

                    const SizedBox(height: 30),

                    // ------------------------------------------------
                    // CAN TEACH
                    // ------------------------------------------------
                    _sectionHeader(
                      title: 'I can teach',
                      subtitle: 'Select skills you feel comfortable sharing.',
                      icon: Icons.school_rounded,
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _skills.map((skill) {
                        return _skillChip(
                          skill: skill,
                          selected: _canTeach.contains(skill),
                          onTap: () => _toggleTeach(skill),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 35),

                    // ------------------------------------------------
                    // WANT TO LEARN
                    // ------------------------------------------------
                    _sectionHeader(
                      title: 'I want to learn',
                      subtitle: 'Choose skills you want to improve.',
                      icon: Icons.auto_awesome_rounded,
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _skills.map((skill) {
                        return _skillChip(
                          skill: skill,
                          selected: _wantToLearn.contains(skill),
                          onTap: () => _toggleLearn(skill),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),

                    // ------------------------------------------------
                    // SUMMARY
                    // ------------------------------------------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${_canTeach.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Can Teach',
                                  style: TextStyle(color: AppTheme.lightText),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 1,
                            height: 45,
                            color: Colors.grey.shade200,
                          ),

                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${_wantToLearn.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Want to Learn',
                                  style: TextStyle(color: AppTheme.lightText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ------------------------------------------------
                    // COMPLETE BUTTON
                    // ------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppTheme.primary.withOpacity(
                            0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Complete Profile 🎉',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
