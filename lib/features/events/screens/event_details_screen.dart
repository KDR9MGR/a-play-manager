import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:a_play_manage/core/models/event_model.dart';
import 'package:a_play_manage/core/models/user_model.dart';
import 'package:a_play_manage/core/theme/colors.dart';
import 'package:a_play_manage/features/auth/providers/auth_provider.dart';
import 'package:a_play_manage/features/events/providers/event_provider.dart';
import 'package:a_play_manage/shared/widgets/custom_app_bar.dart';
import 'package:a_play_manage/shared/widgets/custom_button.dart';
import 'package:a_play_manage/shared/widgets/loading_widget.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  final String eventId;
  
  const EventDetailsScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  Event? _event;
  UserModel? _organizer;
  bool _isLoading = true;
  String? _error;
  final _dateFormat = DateFormat('E, MMM d, yyyy');
  final _timeFormat = DateFormat('h:mm a');
  
  @override
  void initState() {
    super.initState();
    _loadEventData();
  }
  
  Future<void> _loadEventData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final eventRepository = ref.read(eventRepositoryProvider);
      final authRepository = ref.read(authRepositoryProvider);
      
      // Load event details
      final event = await eventRepository.getEventById(widget.eventId);
      
      if (event == null) {
        setState(() {
          _isLoading = false;
          _error = 'Event not found';
        });
        return;
      }
      
      // Load organizer details
      final organizer = await authRepository.getUserById(event.organizerId);
      
      setState(() {
        _event = event;
        _organizer = organizer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load event details: $e';
      });
    }
  }
  
  bool _isCurrentUserOrganizer() {
    final currentUser = ref.read(currentUserProvider).asData?.value;
    if (currentUser == null || _event == null) {
      return false;
    }
    return currentUser.id == _event!.organizerId;
  }
  
  Future<void> _toggleEventStatus() async {
    if (_event == null) return;
    
    final eventNotifier = ref.read(eventNotifierProvider.notifier);
    final success = await eventNotifier.updateEvent(
      eventId: _event!.id,
      isActive: !_event!.isActive,
    );
    
    if (success) {
      // Reload data if successful
      _loadEventData();
    }
  }
  
  Widget _buildEventHeader() {
    return Stack(
      children: [
        // Banner Image
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            image: _event?.bannerImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(_event!.bannerImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _event?.bannerImageUrl == null
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: Colors.white54,
                  ),
                )
              : null,
        ),
        
        // Gradient overlay for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        
        // Status badge
        if (_event != null)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _event!.isActive
                    ? Colors.green.withOpacity(0.8)
                    : Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _event!.isActive ? 'Active' : 'Inactive',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // Paid badge
        if (_event != null && _event!.isPaid)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Paid: \$${_event!.ticketPrice?.toStringAsFixed(2) ?? ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildEventInfo() {
    if (_event == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _event!.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          
          // Date and time
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 8),
              Text(
                '${_dateFormat.format(_event!.startTime)} at ${_timeFormat.format(_event!.startTime)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // End time
          Row(
            children: [
              const Icon(Icons.schedule, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ends: ${_dateFormat.format(_event!.endTime)} at ${_timeFormat.format(_event!.endTime)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Location
          Row(
            children: [
              const Icon(Icons.location_on, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _event!.location,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _event!.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          if (_event!.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Tags
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _event!.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Attendance information
          Text(
            'Attendance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (_event!.maxAttendees != null)
            Row(
              children: [
                const Icon(Icons.people, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Maximum Attendees: ${_event!.maxAttendees}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_add, size: 18),
              const SizedBox(width: 8),
              Text(
                'Current Attendees: ${_event!.attendees.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Organizer information
          Text(
            'Organizer',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (_organizer != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  backgroundImage: _organizer!.profileImageUrl != null
                      ? NetworkImage(_organizer!.profileImageUrl!)
                      : null,
                  child: _organizer!.profileImageUrl == null
                      ? Text(
                          _organizer!.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _organizer!.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _organizer!.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            )
          else
            const Text('Organizer information not available'),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventNotifierProvider);
    
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(
          title: 'Event Details',
          showBackButton: true,
        ),
        body: LoadingWidget(),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Event Details',
          showBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Go Back',
                onPressed: () => context.pop(),
                isOutlined: true,
                width: 150,
              ),
            ],
          ),
        ),
      );
    }
    
    if (_event == null) {
      return const Scaffold(
        appBar: CustomAppBar(
          title: 'Event Details',
          showBackButton: true,
        ),
        body: Center(
          child: Text('Event not found'),
        ),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Event Details',
        showBackButton: true,
        actions: [
          if (_isCurrentUserOrganizer())
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.pushNamed(
                'edit-event',
                pathParameters: {'id': widget.eventId},
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventHeader(),
                _buildEventInfo(),
                const SizedBox(height: 80), // Space for bottom buttons
              ],
            ),
          ),
          
          // Action buttons (for organizer)
          if (_isCurrentUserOrganizer())
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: _event!.isActive
                          ? 'Deactivate Event'
                          : 'Activate Event',
                      onPressed: _toggleEventStatus,
                      isLoading: eventState.isLoading,
                      icon: _event!.isActive
                          ? Icons.unpublished
                          : Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Edit Event',
                      onPressed: () => context.pushNamed(
                        'edit-event',
                        pathParameters: {'id': widget.eventId},
                      ),
                      isOutlined: true,
                      icon: Icons.edit,
                    ),
                  ),
                ],
              ),
            )
          // For attendees, we could add a register button here
        ],
      ),
    );
  }
} 