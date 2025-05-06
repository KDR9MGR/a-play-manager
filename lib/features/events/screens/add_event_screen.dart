import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:a_play_manage/core/theme/colors.dart';
import 'package:a_play_manage/features/auth/providers/auth_provider.dart';
import '../providers/event_provider.dart' as event_provider;
import 'package:a_play_manage/features/events/widgets/event_form_section.dart';
import 'package:a_play_manage/features/events/widgets/event_datetime_picker.dart';
import 'package:a_play_manage/features/events/widgets/ticket_type_form.dart' as ticket_form;
import 'package:a_play_manage/shared/widgets/custom_app_bar.dart';
import 'package:a_play_manage/shared/widgets/custom_button.dart';
import 'package:a_play_manage/shared/widgets/custom_text_field.dart';

// Simple model for ticket type
class TicketType {
  String name;
  double price;
  int quantity;
  
  TicketType({
    required this.name,
    required this.price,
    required this.quantity,
  });
}

// Simple model for zone
class Zone {
  String name;
  int capacity;
  List<TicketType> ticketTypes;
  
  Zone({
    required this.name,
    required this.capacity,
    required this.ticketTypes,
  });
}

class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Current step in the form
  int _currentStep = 0;
  
  // Basic info controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  
  // UI state variables
  File? _bannerImage;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 2));
  bool _isClubEvent = false;
  bool _isPaid = false;
  
  // Layout settings
  String _layoutType = 'standing';
  final _rowsController = TextEditingController();
  final _columnsController = TextEditingController();
  
  // Zone management
  final int _maxZones = 5;
  final List<Zone> _zones = [
    Zone(
      name: 'General',
      capacity: 100,
      ticketTypes: [
        TicketType(name: 'Standard', price: 0.0, quantity: 100),
      ],
    ),
  ];
  
  // Formatters
  final _dateFormat = DateFormat('EEE, MMM d, yyyy');
  final _timeFormat = DateFormat('h:mm a');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    _maxAttendeesController.dispose();
    _rowsController.dispose();
    _columnsController.dispose();
    super.dispose();
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _bannerImage = File(pickedFile.path);
      });
    }
  }

  // Date and time pickers
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
        
        // Update end date if needed
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
        
        // Update end time if needed
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

  // Parse tags from comma-separated string
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

  // Zone management methods
  void _addZone() {
    if (_zones.length >= _maxZones) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum of $_maxZones zones allowed')),
      );
      return;
    }
    
    setState(() {
      _zones.add(
        Zone(
          name: 'Zone ${_zones.length + 1}',
          capacity: 100,
          ticketTypes: [
            TicketType(name: 'Standard', price: 0.0, quantity: 100),
          ],
        ),
      );
    });
  }

  void _removeZone(int index) {
    if (_zones.length > 1) {
      setState(() {
        _zones.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event must have at least one zone')),
      );
    }
  }

  void _addTicketToZone(int zoneIndex) {
    setState(() {
      _zones[zoneIndex].ticketTypes.add(
        TicketType(name: 'Ticket ${_zones[zoneIndex].ticketTypes.length + 1}', price: 0.0, quantity: 50),
      );
    });
  }

  void _removeTicketFromZone(int zoneIndex, int ticketIndex) {
    if (_zones[zoneIndex].ticketTypes.length > 1) {
      setState(() {
        _zones[zoneIndex].ticketTypes.removeAt(ticketIndex);
      });
    }
  }

  // Move to next step
  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep += 1;
      });
    }
  }

  // Move to previous step
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  // Submit the form and create the event
  void _handleCreateEvent() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }

    if (_bannerImage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a banner image')),
        );
      }
      return;
    }

    // Validate total capacity vs max attendees
    if (_layoutType == 'standing') {
      int totalCapacity = 0;
      for (var zone in _zones) {
        totalCapacity += zone.capacity;
      }
      
      final maxAttendees = int.tryParse(_maxAttendeesController.text);
      if (maxAttendees != null && totalCapacity > maxAttendees) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Total zone capacity exceeds maximum attendees')),
          );
        }
        return;
      }
    }

    try {
      // Convert zones to provider format
      final providerZones = _layoutType == 'standing' 
        ? _zones.map((zone) => event_provider.Zone(
            name: zone.name,
            capacity: zone.capacity,
            ticketTypes: zone.ticketTypes.map((t) => event_provider.TicketType(
              name: t.name,
              price: t.price,
              quantity: t.quantity,
            )).toList(),
          )).toList()
        : null;

      await ref.read(event_provider.eventNotifierProvider.notifier).createEventWithZones(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        startTime: _startDate,
        endTime: _endDate,
        organizerId: currentUser.id,
        tags: _parseTags(),
        bannerImage: _bannerImage,
        maxAttendees: int.tryParse(_maxAttendeesController.text),
        isPaid: _isPaid,
        isClubEvent: _isClubEvent,
        layoutType: _layoutType,
        rows: _layoutType == 'seating' ? int.tryParse(_rowsController.text) : null,
        columns: _layoutType == 'seating' ? int.tryParse(_columnsController.text) : null,
        zones: providerZones,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating event: ${e.toString()}')),
        );
      }
    }
  }

  // Get title for current step
  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Basic Information';
      case 1:
        return 'Date & Time';
      case 2:
        return 'Layout Setup';
      case 3:
        return 'Ticketing';
      default:
        return 'Create Event';
    }
  }

  // Step 1: Basic Information
  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner image picker
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                image: _bannerImage != null
                    ? DecorationImage(
                        image: FileImage(_bannerImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _bannerImage == null
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
        
        // Event title
        CustomTextField(
          label: 'Event Title',
          hint: 'Enter a catchy title for your event',
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
        
        // Description
        CustomTextField(
          label: 'Description',
          hint: 'Describe your event in a few sentences',
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
        
        // Location
        CustomTextField(
          label: 'Location',
          hint: 'Where will the event take place?',
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
        
        // Tags
        CustomTextField(
          label: 'Tags (Optional)',
          hint: 'e.g. music, concert, jazz (separate with commas)',
          controller: _tagsController,
          prefixIcon: Icons.tag,
        ),
        const SizedBox(height: 16),
        
        // Club event toggle
        SwitchListTile(
          title: const Text('Club Event'),
          subtitle: const Text('Toggle if this is a club event'),
          value: _isClubEvent,
          onChanged: (value) => setState(() => _isClubEvent = value),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // Step 2: Date & Time
  Widget _buildDateTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start Date & Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        
        // Start date picker
        InkWell(
          onTap: _selectStartDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(_dateFormat.format(_startDate)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Start time picker
        InkWell(
          onTap: _selectStartTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 12),
                Text(_timeFormat.format(_startDate)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        Text(
          'End Date & Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        
        // End date picker
        InkWell(
          onTap: _selectEndDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(_dateFormat.format(_endDate)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // End time picker
        InkWell(
          onTap: _selectEndTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 12),
                Text(_timeFormat.format(_endDate)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Step 3: Layout Setup
  Widget _buildLayoutStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Max attendees
        CustomTextField(
          label: 'Maximum Attendees',
          hint: 'Maximum capacity for your event',
          controller: _maxAttendeesController,
          prefixIcon: Icons.people,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final number = int.tryParse(value);
              if (number == null || number <= 0) {
                return 'Please enter a valid number';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        
        // Layout type selection
        Text(
          'Layout Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        
        // Layout options
        Row(
          children: [
            Expanded(
              child: _buildLayoutOption(
                icon: Icons.people,
                title: 'Standing',
                description: 'Open area with zones',
                isSelected: _layoutType == 'standing',
                onTap: () => setState(() => _layoutType = 'standing'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildLayoutOption(
                icon: Icons.event_seat,
                title: 'Seating',
                description: 'Rows and columns of seats',
                isSelected: _layoutType == 'seating',
                onTap: () => setState(() => _layoutType = 'seating'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Layout specific options
        if (_layoutType == 'seating') ...[
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Rows',
                  hint: 'Number of rows',
                  controller: _rowsController,
                  prefixIcon: Icons.view_week,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_layoutType == 'seating') {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Invalid';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Columns',
                  hint: 'Number of columns',
                  controller: _columnsController,
                  prefixIcon: Icons.view_column,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_layoutType == 'seating') {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Invalid';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          // Zone management header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Event Zones',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _zones.length < _maxZones ? _addZone : null,
                tooltip: 'Add zone',
              ),
            ],
          ),
          const Text(
            'Create different zones for your event (e.g., VIP, General)',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          
          // Zones list
          ...List.generate(_zones.length, (index) {
            return _buildZoneCard(index);
          }),
        ],
      ],
    );
  }

  // Step 4: Ticketing
  Widget _buildTicketingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Paid event toggle
        SwitchListTile(
          title: const Text('Paid Event'),
          subtitle: const Text('Toggle if tickets will be sold'),
          value: _isPaid,
          onChanged: (value) => setState(() => _isPaid = value),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        
        if (_layoutType == 'standing' && _zones.isNotEmpty) ...[
          const Text(
            'Ticket Types by Zone',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          
          // List zones with their ticket types
          ...List.generate(_zones.length, (zoneIndex) {
            final zone = _zones[zoneIndex];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Capacity: ${zone.capacity}'),
                    const Divider(),
                    
                    // Ticket types header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ticket Types',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          onPressed: () => _addTicketToZone(zoneIndex),
                        ),
                      ],
                    ),
                    
                    // Ticket types list
                    ...List.generate(zone.ticketTypes.length, (ticketIndex) {
                      final ticket = zone.ticketTypes[ticketIndex];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: ticket.name,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) => setState(() => ticket.name = value),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: ticket.price.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {
                                  ticket.price = double.tryParse(value) ?? 0.0;
                                }),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: ticket.quantity.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Qty',
                                  isDense: true,
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {
                                  ticket.quantity = int.tryParse(value) ?? 0;
                                }),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: zone.ticketTypes.length > 1
                                  ? () => _removeTicketFromZone(zoneIndex, ticketIndex)
                                  : null,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // Helper to build a zone card
  Widget _buildZoneCard(int index) {
    final zone = _zones[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zone ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_zones.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _removeZone(index),
                    tooltip: 'Remove zone',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: zone.name,
              decoration: const InputDecoration(
                labelText: 'Zone Name',
                hintText: 'e.g., VIP, General',
                isDense: true,
              ),
              onChanged: (value) => setState(() => zone.name = value),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: zone.capacity.toString(),
              decoration: const InputDecoration(
                labelText: 'Capacity',
                hintText: 'Maximum people in this zone',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {
                zone.capacity = int.tryParse(value) ?? 0;
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build a layout option card
  Widget _buildLayoutOption({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(event_provider.eventNotifierProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Event',
        showBackButton: true,
        actions: [
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousStep,
              tooltip: 'Previous step',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentStep ? theme.primaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Step title
              Text(
                _getStepTitle(_currentStep),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Current step content
              if (_currentStep == 0) _buildBasicInfoStep(),
              if (_currentStep == 1) _buildDateTimeStep(),
              if (_currentStep == 2) _buildLayoutStep(),
              if (_currentStep == 3) _buildTicketingStep(),
              
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
                      const Icon(Icons.error_outline, color: Colors.red),
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
              
              // Navigation buttons
              Row(
                children: [
                  if (_currentStep < 3)
                    Expanded(
                      child: CustomButton(
                        text: 'Continue',
                        onPressed: _nextStep,
                        icon: Icons.arrow_forward,
                      ),
                    )
                  else
                    Expanded(
                      child: CustomButton(
                        text: 'Create Event',
                        onPressed: _handleCreateEvent,
                        isLoading: eventState.isLoading,
                        icon: Icons.check,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
