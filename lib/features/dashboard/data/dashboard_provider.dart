import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardData {
  final double totalRevenue;
  final int totalEvents;
  final int totalAttendees;
  final double averageRating;
  final Map<String, double> revenueDistribution;
  final List<ActivityItem> recentActivities;

  DashboardData({
    required this.totalRevenue,
    required this.totalEvents,
    required this.totalAttendees,
    required this.averageRating,
    required this.revenueDistribution,
    required this.recentActivities,
  });
}

class ActivityItem {
  final String title;
  final String subtitle;
  final String time;
  final DateTime timestamp;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.timestamp,
  });
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final firestore = FirebaseFirestore.instance;

  // Get total revenue
  final eventsSnapshot = await firestore.collection('events').get();
  double totalRevenue = 0;
  Map<String, double> revenueByCategory = {
    'Sports': 0,
    'Music': 0,
    'Theater': 0,
    'Others': 0,
  };

  for (var doc in eventsSnapshot.docs) {
    final data = doc.data();
    final revenue = (data['ticketPrice'] as num? ?? 0).toDouble() * (data['attendees']?.length ?? 0);
    totalRevenue += revenue;

    // Calculate revenue by category
    final category = data['category'] as String? ?? 'Others';
    if (revenueByCategory.containsKey(category)) {
      revenueByCategory[category] = (revenueByCategory[category] ?? 0) + revenue;
    } else {
      revenueByCategory['Others'] = (revenueByCategory['Others'] ?? 0) + revenue;
    }
  }

  // Get total attendees
  final totalAttendees = eventsSnapshot.docs.fold<int>(
    0,
    (sum, doc) => sum + ((doc.data()['attendees'] as List?)?.length ?? 0),
  );

  // Get average rating
  double totalRating = 0;
  int ratingCount = 0;
  for (var doc in eventsSnapshot.docs) {
    final ratings = (doc.data()['ratings'] as List?)?.cast<num>();
    if (ratings != null && ratings.isNotEmpty) {
      totalRating += ratings.fold<double>(0, (sum, rating) => sum + rating.toDouble());
      ratingCount += ratings.length;
    }
  }
  final averageRating = ratingCount > 0 ? (totalRating / ratingCount).toDouble() : 0.0;

  // Get recent activities
  final activitiesSnapshot = await firestore
      .collection('activities')
      .orderBy('timestamp', descending: true)
      .limit(5)
      .get();

  final recentActivities = activitiesSnapshot.docs.map((doc) {
    final data = doc.data();
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    return ActivityItem(
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      time: _getTimeAgo(timestamp),
      timestamp: timestamp,
    );
  }).toList();

  return DashboardData(
    totalRevenue: totalRevenue,
    totalEvents: eventsSnapshot.size,
    totalAttendees: totalAttendees,
    averageRating: averageRating,
    revenueDistribution: revenueByCategory,
    recentActivities: recentActivities,
  );
});

String _getTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 0) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'Just now';
  }
} 