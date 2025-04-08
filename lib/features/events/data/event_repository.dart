import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/event_model.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    storage: FirebaseStorage.instance,
  );
});

class EventRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseStorage storage;

  EventRepository({
    required this.firestore,
    required this.auth,
    required this.storage,
  });

  // Get all events for the current organizer
  Stream<List<Event>> getOrganizerEvents() {
    final userId = auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return firestore
        .collection('events')
        .where('organizerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }

  // Get a single event by ID
  Future<Event?> getEventById(String eventId) async {
    final doc = await firestore.collection('events').doc(eventId).get();
    if (!doc.exists) return null;
    return Event.fromFirestore(doc);
  }

  // Create a new event
  Future<String> createEvent({
    required String title,
    required String description,
    required String venue,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required double ticketPrice,
    required int maxAttendees,
    required String category,
    required File? imageFile,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    String imageUrl = '';
    if (imageFile != null) {
      final ref = storage.ref().child('events/${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final eventData = {
      'title': title,
      'description': description,
      'venue': venue,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'ticketPrice': ticketPrice,
      'maxAttendees': maxAttendees,
      'organizerId': user.uid,
      'organizerName': user.displayName ?? '',
      'imageUrl': imageUrl,
      'isActive': true,
      'isFeatured': false,
      'attendees': [],
      'ratings': [],
      'category': category,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };

    final docRef = await firestore.collection('events').add(eventData);
    return docRef.id;
  }

  // Update an existing event
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    String? venue,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    double? ticketPrice,
    int? maxAttendees,
    String? category,
    File? imageFile,
    bool? isActive,
  }) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final event = await getEventById(eventId);
    if (event == null) throw Exception('Event not found');
    if (event.organizerId != user.uid) throw Exception('Not authorized to update this event');

    final updates = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (venue != null) updates['venue'] = venue;
    if (date != null) updates['date'] = Timestamp.fromDate(date);
    if (startTime != null) updates['startTime'] = Timestamp.fromDate(startTime);
    if (endTime != null) updates['endTime'] = Timestamp.fromDate(endTime);
    if (ticketPrice != null) updates['ticketPrice'] = ticketPrice;
    if (maxAttendees != null) updates['maxAttendees'] = maxAttendees;
    if (category != null) updates['category'] = category;
    if (isActive != null) updates['isActive'] = isActive;

    if (imageFile != null) {
      final ref = storage.ref().child('events/${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(imageFile);
      updates['imageUrl'] = await ref.getDownloadURL();

      // Delete old image if exists
      if (event.imageUrl.isNotEmpty) {
        try {
          await storage.refFromURL(event.imageUrl).delete();
        } catch (e) {
          // Ignore errors when deleting old image
        }
      }
    }

    await firestore.collection('events').doc(eventId).update(updates);
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final event = await getEventById(eventId);
    if (event == null) throw Exception('Event not found');
    if (event.organizerId != user.uid) throw Exception('Not authorized to delete this event');

    // Delete event image if exists
    if (event.imageUrl.isNotEmpty) {
      try {
        await storage.refFromURL(event.imageUrl).delete();
      } catch (e) {
        // Ignore errors when deleting image
      }
    }

    await firestore.collection('events').doc(eventId).delete();
  }
} 