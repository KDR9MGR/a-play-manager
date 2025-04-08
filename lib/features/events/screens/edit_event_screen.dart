import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:a_play_manage/core/models/event_model.dart';
import 'package:a_play_manage/core/theme/colors.dart';
import 'package:a_play_manage/features/events/providers/event_provider.dart';
import 'package:a_play_manage/shared/widgets/custom_app_bar.dart';
import 'package:a_play_manage/shared/widgets/custom_button.dart';
import 'package:a_play_manage/shared/widgets/custom_text_field.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final String eventId;
  
  const EditEventScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _ticketPriceController = TextEditingController();
  
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isPaid = false;
  bool _isActive = true;
  File? _bannerImage;
  String? _existingBannerUrl;
  bool _isLoading = true;
  String? _loadError;
  
  final _dateFormat = DateFormat('E, MMM d, yyyy');
  final _timeFormat = DateFormat('h:mm a');
  
  @override
  void initState() {
    super.initState();
    _loadEventData();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    _maxAttendeesController.dispose();
    _ticketPriceController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEventData() async {
    try {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
      
      final eventRepository = ref.read(eventRepositoryProvider);
      final event = await eventRepository.getEventById(widget.eventId);
      
      if (event == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'Event not found';
        });
        return;
      }
      
      // Populate form with event data
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _tagsController.text = event.tags.join(', ');
      
      if (event.maxAttendees != null) {
        _maxAttendeesController.text = event.maxAttendees.toString();
      }
      
      _isPaid = event.isPaid;
      
      if (event.ticketPrice != null) {
        _ticketPriceController.text = event.ticketPrice.toString();
      }
      
      _startDate = event.startTime;
      _endDate = event.endTime;
      _isActive = event.isActive;
      _existingBannerUrl = event.bannerImageUrl;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load event: $e';
      });
    }
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _bannerImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _startDate.hour,
          _startDate.minute,
        );
        
        // If end date is before start date, update it
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 2));
        }
      });
    }
  }
  
  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          picked.hour,
          picked.minute,
        );
        
        // If end time is before start time on the same day, update it
        if (_endDate.year == _startDate.year &&
            _endDate.month == _startDate.month &&
            _endDate.day == _startDate.day &&
            _endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 2));
        }
      });
    }
  }
  
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _endDate.hour,
          _endDate.minute,
        );
      });
    }
  }
  
  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endDate),
    );
    
    if (picked != null) {
      final newEndDate = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        picked.hour,
        picked.minute,
      );
      
      // Only update if end time is after start time when on the same day
      if (_startDate.year != _endDate.year ||
          _startDate.month != _endDate.month ||
          _startDate.day != _endDate.day ||
          newEndDate.isAfter(_startDate)) {
        setState(() {
          _endDate = newEndDate;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  List<String> _parseTags() {
    if (_tagsController.text.trim().isEmpty) {
      return [];
    }
    
    return _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }
  
  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validate times
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final eventNotifier = ref.read(eventNotifierProvider.notifier);
    
    final success = await eventNotifier.updateEvent(
      eventId: widget.eventId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      startTime: _startDate,
      endTime: _endDate,
      tags: _parseTags(),
      bannerImage: _bannerImage,
      maxAttendees: _maxAttendeesController.text.isEmpty
          ? null
          : int.tryParse(_maxAttendeesController.text.trim()),
      ticketPrice: _isPaid && _ticketPriceController.text.isNotEmpty
          ? double.tryParse(_ticketPriceController.text.trim())
          : null,
      isPaid: _isPaid,
      isActive: _isActive,
    );
    
    if (success && context.mounted) {
      context.pop();
      context.pushNamed(
        'event-details',
        pathParameters: {'id': widget.eventId},
      );
    }
  }
  
  Future<void> _deleteEvent() async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text(
            'Are you sure you want to delete this event? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    
    if (confirm == true) {
      final eventNotifier = ref.read(eventNotifierProvider.notifier);
      final success = await eventNotifier.deleteEvent(widget.eventId);
      
      if (success && context.mounted) {
        context.pop();
        context.pushNamed('events');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventNotifierProvider);
    
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Edit Event',
          showBackButton: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_loadError != null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Edit Event',
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
                'Error Loading Event',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _loadError!,
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
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Event',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Image
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        image: _bannerImage != null
                            ? DecorationImage(
                                image: FileImage(_bannerImage!),
                                fit: BoxFit.cover,
                              )
                            : _existingBannerUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_existingBannerUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: _bannerImage == null && _existingBannerUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Banner Image',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Event Status
                SwitchListTile(
                  title: Text(
                    'Event Status',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: _isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green,
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // Event Details
                CustomTextField(
                  label: 'Event Title',
                  hint: 'Enter event title',
                  controller: _titleController,
                  prefixIcon: Icons.event,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an event title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Description',
                  hint: 'Enter event description',
                  controller: _descriptionController,
                  maxLines: 4,
                  prefixIcon: Icons.description,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an event description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Location',
                  hint: 'Enter event location',
                  controller: _locationController,
                  prefixIcon: Icons.location_on,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an event location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Start Date & Time
                Text(
                  'Start Date & Time',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectStartDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 8),
                              Text(_dateFormat.format(_startDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectStartTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 18),
                              const SizedBox(width: 8),
                              Text(_timeFormat.format(_startDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // End Date & Time
                Text(
                  'End Date & Time',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 8),
                              Text(_dateFormat.format(_endDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 18),
                              const SizedBox(width: 8),
                              Text(_timeFormat.format(_endDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tags
                CustomTextField(
                  label: 'Tags',
                  hint: 'Enter comma-separated tags (e.g. music, concert, jazz)',
                  controller: _tagsController,
                  prefixIcon: Icons.tag,
                ),
                const SizedBox(height: 16),
                
                // Max Attendees
                CustomTextField(
                  label: 'Maximum Attendees (optional)',
                  hint: 'Enter maximum attendees',
                  controller: _maxAttendeesController,
                  prefixIcon: Icons.people,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Ticket Price
                SwitchListTile(
                  title: Text(
                    'Paid Event',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    'Toggle if tickets will be sold',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: _isPaid,
                  onChanged: (value) {
                    setState(() {
                      _isPaid = value;
                      if (!value) {
                        _ticketPriceController.clear();
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                if (_isPaid) ...[
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'Ticket Price',
                    hint: 'Enter ticket price',
                    controller: _ticketPriceController,
                    prefixIcon: Icons.monetization_on,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_isPaid && (value == null || value.isEmpty)) {
                        return 'Please enter ticket price';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                
                // Error message
                if (eventState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            eventState.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Success message
                if (eventState.successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            eventState.successMessage!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Update Event Button
                CustomButton(
                  text: 'Update Event',
                  onPressed: _updateEvent,
                  isLoading: eventState.isLoading,
                  icon: Icons.save,
                ),
                const SizedBox(height: 16),
                
                // Delete Event Button
                CustomButton(
                  text: 'Delete Event',
                  onPressed: _deleteEvent,
                  isOutlined: true,
                  icon: Icons.delete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 