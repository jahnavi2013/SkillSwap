import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SwapsScreen extends StatelessWidget {
  const SwapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Swaps',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: const TabBarView(children: [ReceivedRequests(), SentRequests()]),
      ),
    );
  }
}

// ------------------------------------------------------------
// RECEIVED REQUESTS
// ------------------------------------------------------------

class ReceivedRequests extends StatelessWidget {
  const ReceivedRequests({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please login again.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('receiverId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load requests.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const EmptyRequests(
            message: 'No exchange requests yet.',
            subtitle: 'When another student sends you a request, it will appear here.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Exchange requests you received',
              style: TextStyle(color: AppTheme.lightText, fontSize: 14),
            ),
            const SizedBox(height: 16),

            ...requests.map((doc) {
              final data = doc.data();

              return SwapRequestCard(
                requestId: doc.id,
                name: data['senderName']?.toString() ?? 'Student',
                teaches: _firstSkill(data['senderCanTeach']),
                wants: _firstSkill(data['senderWantsToLearn']),
                status: data['status']?.toString() ?? 'pending',
                showActions: data['status']?.toString() == 'pending',
                isSender: false,
                senderCompleted: data['senderCompleted'] == true,
                receiverCompleted: data['receiverCompleted'] == true,
              );
            }),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------
// SENT REQUESTS
// ------------------------------------------------------------

class SentRequests extends StatelessWidget {
  const SentRequests({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please login again.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('senderId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load requests.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const EmptyRequests(
            message: 'You have not sent any requests.',
            subtitle:
                'Find a student in Discover and send an exchange request.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Exchange requests you sent',
              style: TextStyle(color: AppTheme.lightText, fontSize: 14),
            ),
            const SizedBox(height: 16),

            ...requests.map((doc) {
              final data = doc.data();

              return SwapRequestCard(
                requestId: doc.id,
                name: data['receiverName']?.toString() ?? 'Student',
                teaches: _firstSkill(data['receiverCanTeach']),
                wants: _firstSkill(data['receiverWantsToLearn']),
                status: data['status']?.toString() ?? 'pending',
                showActions: false,
                isSender: true,
                senderCompleted: data['senderCompleted'] == true,
                receiverCompleted: data['receiverCompleted'] == true,
              );
            }),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------
// REQUEST CARD
// ------------------------------------------------------------

class SwapRequestCard extends StatelessWidget {
  final String requestId;
  final String name;
  final String teaches;
  final String wants;
  final String status;
  final bool showActions;
  final bool isSender;
  final bool senderCompleted;
  final bool receiverCompleted;

  const SwapRequestCard({
    super.key,
    required this.requestId,
    required this.name,
    required this.teaches,
    required this.wants,
    required this.status,
    required this.showActions,
    required this.isSender,
    required this.senderCompleted,
    required this.receiverCompleted,
  });

  Future<void> _updateRequestStatus(
    BuildContext context,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'status': newStatus});

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'accepted'
                ? 'Request from $name accepted!'
                : 'Request from $name rejected.',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not update the request.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  Future<void> _confirmCompletion(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSwapMessage(context, 'Please log in again.');
      return;
    }

    final requestRef = FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final requestSnapshot = await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw Exception('This exchange request no longer exists.');
        }

        final data = requestSnapshot.data()!;

        if (data['status'] != 'accepted' && data['status'] != 'completed') {
          throw Exception('Only accepted exchanges can be completed.');
        }

        final senderId = data['senderId'] as String?;
        final receiverId = data['receiverId'] as String?;

        if (currentUser.uid != senderId && currentUser.uid != receiverId) {
          throw Exception('You are not a participant in this exchange.');
        }

        final completedField = currentUser.uid == senderId
            ? 'senderCompleted'
            : 'receiverCompleted';

        final senderCompleted =
            data['senderCompleted'] == true ||
            completedField == 'senderCompleted';
        final receiverCompleted =
            data['receiverCompleted'] == true ||
            completedField == 'receiverCompleted';

        final bothCompleted = senderCompleted && receiverCompleted;
        final alreadyAwarded = data['xpAwarded'] == true;

        final updates = <String, dynamic>{completedField: true};

        if (bothCompleted) {
          updates['status'] = 'completed';
        }

        if (bothCompleted && !alreadyAwarded) {
          final senderRef = FirebaseFirestore.instance
              .collection('users')
              .doc(senderId);
          final receiverRef = FirebaseFirestore.instance
              .collection('users')
              .doc(receiverId);

          final senderSnapshot = await transaction.get(senderRef);
          final receiverSnapshot = await transaction.get(receiverRef);

          if (!senderSnapshot.exists || !receiverSnapshot.exists) {
            throw Exception('A participant profile could not be found.');
          }

          final senderData = senderSnapshot.data()!;
          final receiverData = receiverSnapshot.data()!;

          final senderXp = (senderData['xp'] as num?)?.toInt() ?? 0;
          final receiverXp = (receiverData['xp'] as num?)?.toInt() ?? 0;

          transaction.update(senderRef, {'xp': senderXp + 50});
          transaction.update(receiverRef, {'xp': receiverXp + 50});

          updates['xpAwarded'] = true;
        }

        transaction.update(requestRef, updates);
      });

      if (!context.mounted) return;

      _showSwapMessage(
        context,
        'Completion confirmed! Your exchange partner must also confirm.',
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      _showSwapMessage(context, e.message ?? 'Could not confirm completion.');
    } catch (e) {
      if (!context.mounted) return;
      _showSwapMessage(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSwapMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatStatus(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return value;
    }
  }

  IconData _getIcon() {
    final combined = '$teaches $wants'.toLowerCase();

    if (combined.contains('code') ||
        combined.contains('python') ||
        combined.contains('flutter') ||
        combined.contains('program')) {
      return Icons.code_rounded;
    }

    if (combined.contains('design') ||
        combined.contains('ui') ||
        combined.contains('art')) {
      return Icons.palette_rounded;
    }

    if (combined.contains('video')) {
      return Icons.video_library_rounded;
    }

    if (combined.contains('speak')) {
      return Icons.record_voice_over_rounded;
    }

    return Icons.swap_horizontal_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final formattedStatus = _formatStatus(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.background,
                child: Icon(_getIcon(), color: AppTheme.primary, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedStatus,
                      style: TextStyle(
                        color: status.toLowerCase() == 'accepted'
                            ? Colors.green
                            : status.toLowerCase() == 'rejected'
                            ? Colors.redAccent
                            : AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SkillBox(label: 'They teach', skill: teaches),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SkillBox(label: 'They want', skill: wants),
              ),
            ],
          ),

          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _updateRequestStatus(context, 'rejected');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.darkText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.background),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _updateRequestStatus(context, 'accepted');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],

          if (status.toLowerCase() == 'accepted') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isSender ? senderCompleted : receiverCompleted)
                    ? null
                    : () => _confirmCompletion(context),
                icon: Icon(
                  (isSender ? senderCompleted : receiverCompleted)
                      ? Icons.check_circle
                      : Icons.task_alt,
                ),
                label: Text(
                  (isSender ? senderCompleted : receiverCompleted)
                      ? 'You Confirmed Completion'
                      : 'Confirm Completion (+50 XP)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your confirmation: '
              '${(isSender ? senderCompleted : receiverCompleted) ? 'Complete' : 'Pending'}',
              style: const TextStyle(fontSize: 12, color: AppTheme.lightText),
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// EMPTY STATE
// ------------------------------------------------------------

class EmptyRequests extends StatelessWidget {
  final String message;
  final String subtitle;

  const EmptyRequests({
    super.key,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horizontal_circle_outlined,
              size: 70,
              color: AppTheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.lightText),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// SKILL BOX
// ------------------------------------------------------------

class SkillBox extends StatelessWidget {
  final String label;
  final String skill;

  const SkillBox({super.key, required this.label, required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.lightText),
          ),
          const SizedBox(height: 4),
          Text(
            skill,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// HELPER
// ------------------------------------------------------------

String _firstSkill(dynamic value) {
  if (value is List && value.isNotEmpty) {
    return value.first.toString();
  }

  return 'Not specified';
}
