import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:a_play_manage/core/models/event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Create a new event
  Future<String> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    required String organizerId,
    required List<String> tags,
    File? bannerImage,
    int? maxAttendees,
    double? ticketPrice,
    required bool isPaid,
  }) async {
    try {
      // Create a new document reference with auto-generated ID
      final eventRef = _firestore.collection('events').doc();
      String? bannerImageUrl;
      
      // Upload banner image if provided
      if (bannerImage != null) {
        bannerImageUrl = await _uploadBannerImage(eventRef.id, bannerImage);
      }
      
      // Create event object
      final event = Event(
        id: eventRef.id,
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
        organizerId: organizerId,
        attendees: [],
        tags: tags,
        maxAttendees: maxAttendees,
        ticketPrice: ticketPrice,
        isPaid: isPaid,
        isActive: true,
        bannerImageUrl: bannerImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save event to Firestore
      await eventRef.set(event.toMap());
      
      return eventRef.id;
    } catch (e) {
      debugPrint('Error creating event: $e');
      rethrow;
    }
  }
  
  // Upload banner image to Firebase Storage
  Future<String> _uploadBannerImage(String eventId, File imageFile) async {
    try {
      final storageRef = _storage.ref().child('event_banners/$eventId.jpg');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => null);
      
      // Get download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading banner image: $e');
      rethrow;
    }
  }
  
  // Get all events for a specific organizer
  Stream<List<Event>> getOrganizerEvents(String organizerId) {
    try {
      return _firestore
          .collection('events')
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
      });
    } catch (e) {
      debugPrint('Error getting organizer events: $e');
      rethrow;
    }
  }
  
  // Get a single event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      
      if (doc.exists) {
        return Event.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting event by ID: $e');
      rethrow;
    }
  }
  
  // Update an existing event
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? tags,
    File? bannerImage,
    int? maxAttendees,
    double? ticketPrice,
    bool? isPaid,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (location != null) updateData['location'] = location;
      if (startTime != null) updateData['startTime'] = Timestamp.fromDate(startTime);
      if (endTime != null) updateData['endTime'] = Timestamp.fromDate(endTime);
      if (tags != null) updateData['tags'] = tags;
      if (maxAttendees != null) updateData['maxAttendees'] = maxAttendees;
      if (ticketPrice != null) updateData['ticketPrice'] = ticketPrice;
      if (isPaid != null) updateData['isPaid'] = isPaid;
      if (isActive != null) updateData['isActive'] = isActive;
      
      // Upload new banner image if provided
      if (bannerImage != null) {
        final bannerImageUrl = await _uploadBannerImage(eventId, bannerImage);
        updateData['bannerImageUrl'] = bannerImageUrl;
      }
      
      if (updateData.isNotEmpty) {
        await _firestore.collection('events').doc(eventId).update(updateData);
      }
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    }
  }
  
  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      // Delete event document
      await _firestore.collection('events').doc(eventId).delete();
      
      // Delete banner image from storage if it exists
      try {
        await _storage.ref().child('event_banners/$eventId.jpg').delete();
      } catch (_) {
        // Ignore if the image doesn't exist
      }
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }
  
  // Toggle event active status
  Future<void> toggleEventStatus(String eventId, bool isActive) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error toggling event status: $e');
      rethrow;
    }
  }

  // Get all active events
  Stream<List<Event>> getActiveEvents() {
    try {
      return _firestore
          .collection('events')
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
      });
    } catch (e) {
      debugPrint('Error getting active events: $e');
      rethrow;
    }
  }

  // Add attendee to an event
  Future<void> addAttendee(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'attendees': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding attendee to event: $e');
      rethrow;
    }
  }

  // Remove attendee from an event
  Future<void> removeAttendee(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'attendees': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error removing attendee from event: $e');
      rethrow;
    }
  }
} 