
import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeService {
  static const String firstSteps = 'First Steps';
  static const String skillSwapper = 'Skill Swapper';
  static const String xpCollector = 'XP Collector';
  static const String consistencyStar = 'Consistency Star';

  static Future<void> awardBadge(
    String userId,
    String badgeName,
  ) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final badges = List<String>.from(
        data['badges'] ?? <String>[],
      );

      if (badges.contains(badgeName)) {
        return;
      }

      badges.add(badgeName);

      transaction.update(userRef, {
        'badges': badges,
      });
    });
  }

  static Future<void> awardXpCollectorIfEligible(
    String userId,
    int totalXp,
  ) async {
    if (totalXp >= 100) {
      await awardBadge(userId, xpCollector);
    }
  }

  static Future<void> awardConsistencyStarIfEligible(
    String userId,
    int currentStreak,
  ) async {
    if (currentStreak >= 7) {
      await awardBadge(userId, consistencyStar);
    }
  }
}