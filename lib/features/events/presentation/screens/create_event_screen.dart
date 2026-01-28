import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/events_provider.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _eventNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _capacityController = TextEditingController(text: '100');
  final _priceController = TextEditingController(text: '0');
  final _imageUrlController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _eventType = 'other';

  final List<String> _eventTypes = const [
    'festival',
    'prayer',
    'workshop',
    'other',
  ];

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: _selectedDate ?? now,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final dt = DateTime(2000, 1, 1, time.hour, time.minute);
    return DateFormat.jm().format(dt); // e.g. 2:33 PM
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select event date and time')),
      );
      return;
    }

    final provider = context.read<EventsProvider>();
    if (!provider.canCreateEvent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only temples and creators can create events')),
      );
      return;
    }

    final capacity = int.tryParse(_capacityController.text.trim()) ?? 100;
    final price = num.tryParse(_priceController.text.trim()) ?? 0;

    final eventDateTime = _combineDateAndTime(_selectedDate!, _selectedTime!);
    final eventTimeStr = _formatTime(_selectedTime!);

    final imageUrl = _imageUrlController.text.trim();
    final imageList = imageUrl.isNotEmpty ? <String>[imageUrl] : <String>[];

    final ok = await provider.createEvent(
      eventName: _eventNameController.text.trim(),
      description: _descriptionController.text.trim(),
      eventDate: eventDateTime,
      eventTime: eventTimeStr,
      location: _locationController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      eventImage: imageList,
      capacity: capacity,
      eventType: _eventType,
      price: price,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Event created!' : (provider.error ?? 'Failed'))),
    );

    if (ok) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<EventsProvider>();

    final dateLabel = _selectedDate == null
        ? 'Select date'
        : DateFormat('dd MMM yyyy').format(_selectedDate!);

    final timeLabel = _selectedTime == null ? 'Select time' : _formatTime(_selectedTime!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                labelText: 'Event Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(dateLabel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(timeLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _eventType,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                border: OutlineInputBorder(),
              ),
              items: _eventTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _eventType = v ?? 'other'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Event Image URL (optional)',
                border: OutlineInputBorder(),
              ),
            ),

            if (provider.error != null) ...[
              const SizedBox(height: 12),
              Text(
                provider.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.isLoading ? null : _submit,
              child: provider.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}
