import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String venue;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final double ticketPrice;
  final int maxAttendees;
  final String organizerId;
  final String organizerName;
  final String imageUrl;
  final bool isActive;
  final bool isFeatured;
  final List<String> attendees;
  final List<double> ratings;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.ticketPrice,
    required this.maxAttendees,
    required this.organizerId,
    required this.organizerName,
    required this.imageUrl,
    required this.isActive,
    required this.isFeatured,
    required this.attendees,
    required this.ratings,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      venue: data['venue'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      ticketPrice: (data['ticketPrice'] as num).toDouble(),
      maxAttendees: data['maxAttendees'] ?? 0,
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      attendees: List<String>.from(data['attendees'] ?? []),
      ratings: List<double>.from((data['ratings'] ?? []).map((r) => (r as num).toDouble())),
      category: data['category'] ?? 'Others',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'venue': venue,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'ticketPrice': ticketPrice,
      'maxAttendees': maxAttendees,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'attendees': attendees,
      'ratings': ratings,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Event copyWith({
    String? title,
    String? description,
    String? venue,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    double? ticketPrice,
    int? maxAttendees,
    String? imageUrl,
    bool? isActive,
    bool? isFeatured,
    String? category,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      venue: venue ?? this.venue,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      organizerId: organizerId,
      organizerName: organizerName,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      attendees: attendees,
      ratings: ratings,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 