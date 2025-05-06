import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:a_play_manage/features/events/repository/event_repository.dart';
import 'package:a_play_manage/core/models/event_model.dart';
import 'package:a_play_manage/features/auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';

// Ticket type class
class TicketType {
  final String name;
  final double price;
  final int quantity;
  
  TicketType({
    required this.name,
    required this.price,
    required this.quantity,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory TicketType.fromMap(Map<String, dynamic> map) {
    return TicketType(
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
    );
  }
}

// Zone model class
class Zone {
  final String name;
  final int capacity;
  final List<TicketType> ticketTypes;
  
  Zone({
    required this.name,
    required this.capacity,
    required this.ticketTypes,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
      'ticketTypes': ticketTypes.map((t) => t.toMap()).toList(),
    };
  }
  
  factory Zone.fromMap(Map<String, dynamic> map) {
    return Zone(
      name: map['name'] ?? '',
      capacity: map['capacity'] ?? 0,
      ticketTypes: List<TicketType>.from(
        (map['ticketTypes'] ?? []).map((t) => TicketType.fromMap(t)),
      ),
    );
  }
}

// Event repository provider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

// Organizer events provider
final organizerEventsProvider = StreamProvider<List<Event>>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider).asData?.value;
  
  if (currentUser != null) {
    return eventRepository.getOrganizerEvents(currentUser.id);
  }
  
  return Stream.value([]);
});

// All active events provider
final activeEventsProvider = StreamProvider<List<Event>>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  // Implement this method in EventRepository
  return eventRepository.getActiveEvents();
});

// Single event provider
final eventProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return await eventRepository.getEventById(eventId);
});

// Event state for create/update operations
class EventState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  
  const EventState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });
  
  EventState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return EventState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Event notifier for create/update/delete operations
class EventNotifier extends StateNotifier<EventState> {
  final EventRepository _eventRepository;
  
  EventNotifier(this._eventRepository) : super(const EventState());
  
  // Create a new event
  Future<String?> createEvent({
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
    bool isClubEvent = false,
    String layoutType = 'standing',
    int? rows,
    int? columns,
    List<TicketType>? ticketTypes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null, successMessage: null);
      
      // Convert ticket types to maps if provided
      List<Map<String, dynamic>>? ticketTypeMaps;
      if (ticketTypes != null) {
        ticketTypeMaps = ticketTypes.map((ticket) => ticket.toMap()).toList();
      }
      
      final eventId = await _eventRepository.createEvent(
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
        organizerId: organizerId,
        tags: tags,
        bannerImage: bannerImage,
        maxAttendees: maxAttendees,
        ticketPrice: ticketPrice,
        isPaid: isPaid,
        isClubEvent: isClubEvent,
        layoutType: layoutType,
        rows: rows,
        columns: columns,
        ticketTypes: ticketTypeMaps,
      );
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Event created successfully',
      );
      
      return eventId;
    } catch (e) {
      debugPrint('Error in createEvent: $e');
      String errorMessage = 'Failed to create event';
      
      // Create a more user-friendly error message
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'You do not have permission to create events. Please check your account status.';
      } else if (e.toString().contains('unauthorized')) {
        errorMessage = 'Unable to upload image. Please try again or choose a different image.';
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
      return null;
    }
  }
  
  // Update an existing event
  Future<bool> updateEvent({
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
      state = state.copyWith(isLoading: true, error: null, successMessage: null);
      
      await _eventRepository.updateEvent(
        eventId: eventId,
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
        tags: tags,
        bannerImage: bannerImage,
        maxAttendees: maxAttendees,
        ticketPrice: ticketPrice,
        isPaid: isPaid,
        isActive: isActive,
      );
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Event updated successfully',
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  // Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      state = state.copyWith(isLoading: true, error: null, successMessage: null);
      
      await _eventRepository.deleteEvent(eventId);
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Event deleted successfully',
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  // Register for an event
  Future<bool> registerForEvent(String eventId, String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null, successMessage: null);
      
      // Implement this method in EventRepository
      await _eventRepository.addAttendee(eventId, userId);
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Registered for event successfully',
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  
  // Clear state
  void clearState() {
    state = const EventState();
  }

  // Add createEventWithZones method to the EventNotifier class
  Future<void> createEventWithZones({
    required String title,
    required String description,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    required String organizerId,
    required List<String> tags,
    required File? bannerImage,
    int? maxAttendees,
    required bool isPaid,
    required bool isClubEvent,
    required String layoutType,
    int? rows,
    int? columns,
    List<Zone>? zones,
  }) async {
    try {
      state = const EventState(isLoading: true);
      
      // Upload banner image to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();
      final bannerPath = 'events/banners/${DateTime.now().millisecondsSinceEpoch}_${path.basename(bannerImage!.path)}';
      final bannerRef = storageRef.child(bannerPath);
      
      await bannerRef.putFile(bannerImage);
      final bannerUrl = await bannerRef.getDownloadURL();
      
      // Create event data
      final eventData = {
        'title': title,
        'description': description,
        'location': location,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'organizerId': organizerId,
        'tags': tags,
        'bannerUrl': bannerUrl,
        'maxAttendees': maxAttendees,
        'isPaid': isPaid,
        'isClubEvent': isClubEvent,
        'layoutType': layoutType,
        'rows': rows,
        'columns': columns,
        'createdAt': Timestamp.now(),
      };
      
      // Add the event to Firestore
      final eventsCollection = FirebaseFirestore.instance.collection('events');
      final eventRef = await eventsCollection.add(eventData);
      
      // If zones are provided, create a subcollection for them
      if (zones != null && zones.isNotEmpty) {
        final zonesCollection = eventRef.collection('zones');
        
        for (final zone in zones) {
          await zonesCollection.add(zone.toMap());
        }
      }
      
      state = const EventState();
    } catch (e) {
      state = EventState(error: e.toString());
      rethrow;
    }
  }
}

final eventNotifierProvider = StateNotifierProvider<EventNotifier, EventState>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return EventNotifier(eventRepository);
}); 