import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'event_repository.dart';
import '../domain/event_model.dart';

final organizerEventsProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getOrganizerEvents();
});

final selectedEventProvider = StateProvider<Event?>((ref) => null);

final eventControllerProvider = Provider((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return EventController(repository: repository);
});

class EventController {
  final EventRepository repository;

  EventController({required this.repository});

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
    File? imageFile,
  }) async {
    return repository.createEvent(
      title: title,
      description: description,
      venue: venue,
      date: date,
      startTime: startTime,
      endTime: endTime,
      ticketPrice: ticketPrice,
      maxAttendees: maxAttendees,
      category: category,
      imageFile: imageFile,
    );
  }

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
    await repository.updateEvent(
      eventId: eventId,
      title: title,
      description: description,
      venue: venue,
      date: date,
      startTime: startTime,
      endTime: endTime,
      ticketPrice: ticketPrice,
      maxAttendees: maxAttendees,
      category: category,
      imageFile: imageFile,
      isActive: isActive,
    );
  }

  Future<void> deleteEvent(String eventId) async {
    await repository.deleteEvent(eventId);
  }

  Future<Event?> getEventById(String eventId) async {
    return repository.getEventById(eventId);
  }
} 