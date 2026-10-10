import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  String? _selectedSkill;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadMatches() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return [];
    }

    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!currentUserDoc.exists) {
      return [];
    }

    final currentData = currentUserDoc.data() ?? {};

    final List<String> wantsToLearn = List<String>.from(
      currentData['wantsToLearn'] ?? [],
    );

    if (wantsToLearn.isEmpty) {
      return [];
    }

    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    final List<Map<String, dynamic>> matches = [];

    for (final doc in snapshot.docs) {
      // Don't show yourself.
      if (doc.id == currentUser.uid) {
        continue;
      }

      final data = doc.data();

      final String name = data['name'] ?? 'Student';

      final List<String> canTeach = List<String>.from(data['canTeach'] ?? []);

      final List<String> otherWantsToLearn = List<String>.from(
        data['wantsToLearn'] ?? [],
      );

      // Skills you want to learn that this student can teach.
      // ------------------------------------------------------------
      // NORMALIZED SKILL MATCHING
      // ------------------------------------------------------------

      String normalizeSkill(String skill) {
        return skill.trim().toLowerCase();
      }

      // Skills you want to learn that this student can teach.
      final List<String> matchingSkills = wantsToLearn.where((wantedSkill) {
        final normalizedWantedSkill = normalizeSkill(wantedSkill);

        return canTeach.any(
          (teachingSkill) =>
              normalizeSkill(teachingSkill) == normalizedWantedSkill,
        );
      }).toList();

      if (matchingSkills.isEmpty) {
        continue;
      }

      // Also calculate the reverse direction:
      // skills this student wants to learn that YOU can teach.

      final List<String> yourCanTeach = List<String>.from(
        currentData['canTeach'] ?? [],
      );

      final List<String> reverseMatches = otherWantsToLearn.where((
        wantedSkill,
      ) {
        final normalizedWantedSkill = normalizeSkill(wantedSkill);

        return yourCanTeach.any(
          (yourTeachingSkill) =>
              normalizeSkill(yourTeachingSkill) == normalizedWantedSkill,
        );
      }).toList();

      // Main match score based on what you want to learn.
      final double learningScore = matchingSkills.length / wantsToLearn.length;

      // Small bonus for a two-way exchange.
      final double exchangeBonus = reverseMatches.isNotEmpty ? 0.2 : 0.0;

      final double finalScore = ((learningScore + exchangeBonus).clamp(
        0.0,
        1.0,
      ));

      final int matchPercentage = (finalScore * 100).round();

      matches.add({
        'id': doc.id,
        'name': name,
        'college': data['college'] ?? '',
        'course': data['course'] ?? '',
        'year': data['year'] ?? '',
        'canTeach': canTeach,
        'wantsToLearn': otherWantsToLearn,
        'matchingSkills': matchingSkills,
        'reverseMatches': reverseMatches,
        'matchPercentage': matchPercentage,
      });
    }

    // Highest matches first.
    matches.sort(
      (a, b) =>
          (b['matchPercentage'] as int).compareTo(a['matchPercentage'] as int),
    );

    return matches;
  }

  List<Map<String, dynamic>> _filterMatches(
    List<Map<String, dynamic>> matches,
  ) {
    return matches.where((student) {
      final String name = (student['name'] ?? '').toString().toLowerCase();

      final List<String> canTeach = List<String>.from(
        student['canTeach'] ?? [],
      );

      final List<String> matchingSkills = List<String>.from(
        student['matchingSkills'] ?? [],
      );

      final bool matchesSearch =
          _searchText.isEmpty ||
          name.contains(_searchText) ||
          canTeach.any((skill) => skill.toLowerCase().contains(_searchText));

      final bool matchesSkill =
          _selectedSkill == null || matchingSkills.contains(_selectedSkill);

      return matchesSearch && matchesSkill;
    }).toList();
  }

  Future<void> _sendRequest(Map<String, dynamic> student) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage('Please login again.');
      return;
    }

    final receiverId = student['id']?.toString();

    if (receiverId == null || receiverId.isEmpty) {
      _showMessage('Could not identify this student.');
      return;
    }

    if (receiverId == currentUser.uid) {
      _showMessage('You cannot send a request to yourself.');
      return;
    }

    try {
      final requestsRef = FirebaseFirestore.instance.collection('requests');

      // Prevent duplicate pending requests.
      final existingRequest = await requestsRef
          .where('senderId', isEqualTo: currentUser.uid)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        _showMessage('You already sent a request to this student.');
        return;
      }

      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final currentData = currentUserDoc.data() ?? {};

      final senderName =
          currentData['name'] ?? currentUser.displayName ?? 'Student';

      final senderCanTeach = List<String>.from(currentData['canTeach'] ?? []);

      final senderWantsToLearn = List<String>.from(
        currentData['wantsToLearn'] ?? [],
      );

      final receiverName = student['name'] ?? 'Student';

      final receiverCanTeach = List<String>.from(student['canTeach'] ?? []);

      final receiverWantsToLearn = List<String>.from(
        student['wantsToLearn'] ?? [],
      );

      await requestsRef.add({
        'senderId': currentUser.uid,
        'senderName': senderName,
        'senderCanTeach': senderCanTeach,
        'senderWantsToLearn': senderWantsToLearn,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'receiverCanTeach': receiverCanTeach,
        'receiverWantsToLearn': receiverWantsToLearn,
        'status': 'pending',
        'senderCompleted': false,
        'receiverCompleted': false,
        'xpAwarded': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showMessage('Exchange request sent to $receiverName! 🎉');
    } on FirebaseException catch (e) {
      _showMessage(e.message ?? 'Could not send the request.');
    } catch (e) {
      _showMessage('Something went wrong. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Could not load students.',
                style: TextStyle(color: AppTheme.darkText),
              ),
            );
          }

          final allMatches = snapshot.data ?? [];
          final matches = _filterMatches(allMatches);

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Find your next skill exchange 🔍',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Discover students who can teach what you want to learn.',
                  style: TextStyle(fontSize: 14, color: AppTheme.lightText),
                ),

                const SizedBox(height: 20),

                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search students or skills...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.clear_rounded),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Popular skills
                const Text(
                  'Skills you can learn',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),

                const SizedBox(height: 12),

                if (allMatches.isEmpty)
                  const Text(
                    'No matches yet. Add more skills to your profile or invite another student.',
                    style: TextStyle(color: AppTheme.lightText),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getAvailableSkills(allMatches)
                        .map(
                          (skill) => ChoiceChip(
                            label: Text(skill),
                            selected: _selectedSkill == skill,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSkill = selected ? skill : null;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 24),

                // Match count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_alt_rounded,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${matches.length} potential '
                        '${matches.length == 1 ? 'match' : 'matches'} found',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (matches.isEmpty)
                  _EmptySearch()
                else
                  ...matches.map(
                    (student) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _StudentCard(
                        student: student,
                        onRequest: () => _sendRequest(student),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _getAvailableSkills(List<Map<String, dynamic>> matches) {
    final Set<String> skills = {};

    for (final student in matches) {
      final List<String> matchingSkills = List<String>.from(
        student['matchingSkills'] ?? [],
      );

      skills.addAll(matchingSkills);
    }

    return skills.take(8).toList();
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onRequest;

  const _StudentCard({required this.student, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final String name = student['name'] ?? 'Student';
    final String college = student['college'] ?? '';
    final String course = student['course'] ?? '';
    final String year = student['year'] ?? '';

    final List<String> canTeach = List<String>.from(student['canTeach'] ?? []);

    final List<String> matchingSkills = List<String>.from(
      student['matchingSkills'] ?? [],
    );

    final List<String> reverseMatches = List<String>.from(
      student['reverseMatches'] ?? [],
    );

    final int matchPercentage = student['matchPercentage'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primary,
                  size: 32,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),

                    if (course.isNotEmpty || year.isNotEmpty)
                      const SizedBox(height: 3),

                    if (course.isNotEmpty || year.isNotEmpty)
                      Text(
                        '$course${year.isNotEmpty ? ' • $year' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.lightText,
                        ),
                      ),

                    if (college.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        college,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$matchPercentage%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Text(
            'Can teach',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: canTeach.map((skill) {
              final bool isMatch = matchingSkills.contains(skill);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isMatch
                      ? AppTheme.primary.withOpacity(0.12)
                      : AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  skill,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMatch ? AppTheme.primary : AppTheme.darkText,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          if (matchingSkills.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Can teach you: ${matchingSkills.join(', ')}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),

          if (reverseMatches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: AppTheme.orange,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'They want to learn: ${reverseMatches.join(', ')}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Send Exchange Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 55, color: AppTheme.primary),
          SizedBox(height: 14),
          Text(
            'No matches found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try another search or add more skills to your profile.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.lightText),
          ),
        ],
      ),
    );
  }
}
