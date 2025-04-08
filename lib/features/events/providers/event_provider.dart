import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:a_play_manage/features/events/repository/event_repository.dart';
import 'package:a_play_manage/core/models/event_model.dart';
import 'package:a_play_manage/features/auth/providers/auth_provider.dart';

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
  
  EventState({
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
  
  EventNotifier(this._eventRepository) : super(EventState());
  
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
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null, successMessage: null);
      
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
      );
      
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Event created successfully',
      );
      
      return eventId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    state = EventState();
  }
}

final eventNotifierProvider = StateNotifierProvider<EventNotifier, EventState>((ref) {
  final eventRepository = ref.watch(eventRepositoryProvider);
  return EventNotifier(eventRepository);
}); 