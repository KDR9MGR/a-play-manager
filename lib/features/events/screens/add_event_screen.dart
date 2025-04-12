import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:a_play_manage/core/theme/colors.dart';
import 'package:a_play_manage/features/auth/providers/auth_provider.dart';
import 'package:a_play_manage/features/events/providers/event_provider.dart';
import 'package:a_play_manage/shared/widgets/custom_app_bar.dart';
import 'package:a_play_manage/shared/widgets/custom_button.dart';
import 'package:a_play_manage/shared/widgets/custom_text_field.dart';

class AddEventScreen extends ConsumerStatefulWidget {
  const AddEventScreen({super.key});

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _ticketPriceController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  bool _isPaid = false;
  File? _bannerImage;

  // Add new fields for club event and layout type
  bool _isClubEvent = false;
  String _layoutType = 'standing'; // 'seating' or 'standing'
  final _rowsController = TextEditingController();
  final _columnsController = TextEditingController();
  final List<TicketType> _ticketTypes = [
    TicketType(name: 'General Admission', price: 0.0, quantity: 100)
  ];

  final _dateFormat = DateFormat('E, MMM d, yyyy');
  final _timeFormat = DateFormat('h:mm a');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    _maxAttendeesController.dispose();
    _ticketPriceController.dispose();
    _rowsController.dispose();
    _columnsController.dispose();
    super.dispose();
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

  // Add a method to add a ticket type
  void _addTicketType() {
    setState(() {
      _ticketTypes.add(TicketType(name: '', price: 0.0, quantity: 0));
    });
  }

  // Add a method to remove a ticket type
  void _removeTicketType(int index) {
    if (_ticketTypes.length > 1) {
      setState(() {
        _ticketTypes.removeAt(index);
      });
    }
  }

  Future<void> _createEvent() async {
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

    // Validate seating layout
    if (_layoutType == 'seating') {
      if (_rowsController.text.isEmpty || _columnsController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the number of rows and columns'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // Validate ticket types for standing layout
    if (_layoutType == 'standing') {
      bool hasEmptyFields = false;
      for (var ticket in _ticketTypes) {
        if (ticket.name.isEmpty) {
          hasEmptyFields = true;
          break;
        }
      }

      if (hasEmptyFields) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all ticket type details'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // Get user data
    final userAsync = await ref.read(currentUserProvider.future);

    if (userAsync == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User data not available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final eventNotifier = ref.read(eventNotifierProvider.notifier);

    final eventId = await eventNotifier.createEvent(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      startTime: _startDate,
      endTime: _endDate,
      organizerId: userAsync.id,
      tags: _parseTags(),
      bannerImage: _bannerImage,
      maxAttendees: _maxAttendeesController.text.isEmpty
          ? null
          : int.tryParse(_maxAttendeesController.text.trim()),
      ticketPrice: _isPaid && _ticketPriceController.text.isNotEmpty
          ? double.tryParse(_ticketPriceController.text.trim())
          : null,
      isPaid: _isPaid,
      isClubEvent: _isClubEvent,
      layoutType: _layoutType,
      rows:
          _layoutType == 'seating' ? int.tryParse(_rowsController.text) : null,
      columns: _layoutType == 'seating'
          ? int.tryParse(_columnsController.text)
          : null,
      ticketTypes: _layoutType == 'standing' ? _ticketTypes : null,
    );

    if (eventId != null) {
      if (context.mounted) {
        context.pop();
        context.pushNamed(
          'event-details',
          pathParameters: {'id': eventId},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventNotifierProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Create Event',
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
                  hint:
                      'Enter comma-separated tags (e.g. music, concert, jazz)',
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

                // After the Max Attendees field, add Club Event toggle
                const SizedBox(height: 16),

                // Club Event Toggle
                SwitchListTile(
                  title: Text(
                    'Club Event',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    'Toggle if this is a club event',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: _isClubEvent,
                  onChanged: (value) {
                    setState(() {
                      _isClubEvent = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                // After the Club Event toggle, add Layout Type selection
                const SizedBox(height: 16),

                // Layout Type Selection
                Text(
                  'Event Layout',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          'Standing',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        value: 'standing',
                        groupValue: _layoutType,
                        onChanged: (value) {
                          setState(() {
                            _layoutType = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          'Seating',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        value: 'seating',
                        groupValue: _layoutType,
                        onChanged: (value) {
                          setState(() {
                            _layoutType = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),

                // Conditional UI based on layout type
                if (_layoutType == 'seating') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Seating Layout',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
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
                            if (_layoutType == 'seating' &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter rows';
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
                            if (_layoutType == 'seating' &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter columns';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                if (_layoutType == 'standing') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ticket Types',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: _addTicketType,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._ticketTypes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ticket = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ticket Type ${index + 1}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                if (_ticketTypes.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _removeTicketType(index),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Ticket Name',
                                hintText: 'e.g., VIP, General',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: ticket.name,
                              onChanged: (value) {
                                setState(() {
                                  _ticketTypes[index].name = value;
                                });
                              },
                              validator: (value) {
                                if (_layoutType == 'standing' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter ticket name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Price',
                                      hintText: 'Enter price',
                                      border: OutlineInputBorder(),
                                      prefixText: '\$',
                                    ),
                                    initialValue: ticket.price.toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {
                                        _ticketTypes[index].price =
                                            double.tryParse(value) ?? 0.0;
                                      });
                                    },
                                    validator: (value) {
                                      if (_layoutType == 'standing' &&
                                          (value == null || value.isEmpty)) {
                                        return 'Please enter price';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity',
                                      hintText: 'Available tickets',
                                      border: OutlineInputBorder(),
                                    ),
                                    initialValue: ticket.quantity.toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {
                                        _ticketTypes[index].quantity =
                                            int.tryParse(value) ?? 0;
                                      });
                                    },
                                    validator: (value) {
                                      if (_layoutType == 'standing' &&
                                          (value == null || value.isEmpty)) {
                                        return 'Please enter quantity';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                // Ticket Price
                const SizedBox(height: 16),
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
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),

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

                // Create Event Button
                CustomButton(
                  text: 'Create Event',
                  onPressed: _createEvent,
                  isLoading: eventState.isLoading,
                  icon: Icons.add,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
