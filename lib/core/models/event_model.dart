import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String organizerId;
  final List<String> attendees;
  final List<String> tags;
  final int? maxAttendees;
  final double? ticketPrice;
  final bool isPaid;
  final bool isActive;
  final String? bannerImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.organizerId,
    required this.attendees,
    required this.tags,
    this.maxAttendees,
    this.ticketPrice,
    required this.isPaid,
    required this.isActive,
    this.bannerImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    String? organizerId,
    List<String>? attendees,
    List<String>? tags,
    int? maxAttendees,
    double? ticketPrice,
    bool? isPaid,
    bool? isActive,
    String? bannerImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      organizerId: organizerId ?? this.organizerId,
      attendees: attendees ?? this.attendees,
      tags: tags ?? this.tags,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      isPaid: isPaid ?? this.isPaid,
      isActive: isActive ?? this.isActive,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'organizerId': organizerId,
      'attendees': attendees,
      'tags': tags,
      'maxAttendees': maxAttendees,
      'ticketPrice': ticketPrice,
      'isPaid': isPaid,
      'isActive': isActive,
      'bannerImageUrl': bannerImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map, String id) {
    return Event(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      organizerId: map['organizerId'] ?? '',
      attendees: List<String>.from(map['attendees'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      maxAttendees: map['maxAttendees'],
      ticketPrice: map['ticketPrice']?.toDouble(),
      isPaid: map['isPaid'] ?? false,
      isActive: map['isActive'] ?? true,
      bannerImageUrl: map['bannerImageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Event.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return Event.fromMap(data, snapshot.id);
  }
} 