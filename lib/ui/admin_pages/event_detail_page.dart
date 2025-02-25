import 'package:flutter/material.dart';

class EventDetailPage extends StatefulWidget {
  final DateTime selectedDay;
  final Function(String, bool, DateTime, DateTime, String, String?, int?)
      onSave;

  const EventDetailPage({
    super.key,
    required this.selectedDay,
    required this.onSave,
  });

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final TextEditingController _eventNameController = TextEditingController();
  bool _isAllDay = false;
  DateTime? _startTime;
  DateTime? _endTime;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime(widget.selectedDay.year, widget.selectedDay.month,
        widget.selectedDay.day, 9, 0);
    _endTime = DateTime(widget.selectedDay.year, widget.selectedDay.month,
        widget.selectedDay.day, 17, 0);
  }

  void _saveEvent() {
    if (_eventNameController.text.isEmpty) return;

    widget.onSave(
      _eventNameController.text,
      _isAllDay,
      _startTime ?? DateTime.now(),
      _endTime ?? DateTime.now(),
      _locationController.text,
      _descriptionController.text.isEmpty ? null : _descriptionController.text,
      null, // You can pass an optional integer here if needed
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_eventNameController, 'Event Name', Icons.event),
            const SizedBox(height: 10),
            _buildAllDaySwitch(),
            const SizedBox(height: 10),
            const Text('From:', style: TextStyle(fontSize: 16)),
            _buildTimeSelector('Start Time', _startTime, (newTime) {
              setState(() {
                _startTime = newTime;
              });
            }),
            const SizedBox(height: 10),
            const Text('To:', style: TextStyle(fontSize: 16)),
            _buildTimeSelector('End Time', _endTime, (newTime) {
              setState(() {
                _endTime = newTime;
              });
            }),
            const SizedBox(height: 10),
            _buildTextField(_locationController, 'Location', Icons.location_on),
            const SizedBox(height: 10),
            _buildTextField(
                _descriptionController, 'Description', Icons.description),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAllDaySwitch() {
    return Row(
      children: [
        const Text('All Day Event'),
        Switch(
          value: _isAllDay,
          onChanged: (value) {
            setState(() {
              _isAllDay = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
      String label, DateTime? time, Function(DateTime) onTimeChanged) {
    return GestureDetector(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(time),
        );
        if (newTime != null) {
          onTimeChanged(DateTime(
              time.year, time.month, time.day, newTime.hour, newTime.minute));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          '${time!.hour}:${time.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
