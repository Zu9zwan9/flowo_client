import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../blocs/calendar/calendar_cubit.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  String _selectedCategory = 'Brainstorm';
  bool _remindMe = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('Add New Event'),
    ),
    body: Form(
    key: _formKey,
    child: ListView(
    padding: const EdgeInsets.all(16.0),
    children: [
    TextFormField(
    controller: _titleController,
    decoration: const InputDecoration(
    labelText: 'Event name*',
    border: OutlineInputBorder(),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter an event name';
    }
    return null;
    },
    ),
    const SizedBox(height: 16.0),
    TextFormField(
    controller: _descriptionController,
    decoration: const InputDecoration(
    labelText: 'Type the note here...',
    border: OutlineInputBorder(),
    ),
    maxLines: 3,
    ),
    const SizedBox(height: 16.0),
    ListTile(
    title: Text('Date: ${_selectedDate.toString().split(' ')[0]}'),
    trailing: const Icon(Icons.calendar_today),
    onTap: () async {
    final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2025),
    );
    if (picked != null) {
    setState(() {
    _selectedDate = picked;
    });
    }
    },
    ),
    Row(
    children: [
    Expanded(
    child: ListTile(
    title: Text('Start: ${_startTime.format(context)}'),
    trailing: const Icon(Icons.access_time),
    onTap: () async {
    final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _startTime,
    );
    if (picked != null) {
    setState(() {
    _startTime = picked;
    });
    }
    },
    ),
    ),
    Expanded(
    child: ListTile(
    title: Text(_endTime == null
    ? 'End Time'
        : _endTime!.format(context)),
    trailing: const Icon(Icons.access_time),
    onTap: () async {
    final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
    setState(() {
    _endTime = picked;
    });
    }
    },
    ),
    ),
    ],
    ),
    const SizedBox(height: 16.0),
    SwitchListTile(
    title: const Text('Remind me'),
    value: _remindMe,
    onChanged: (bool value) {
    setState(() {
    _remindMe = value;
    });
    },
    ),
    const SizedBox(height: 16.0),
    const Text('Select Category'),
    Wrap(
    spacing: 8.0,
    children: [
    ChoiceChip(
    label: const Text('Brainstorm'),
    selected: _selectedCategory == 'Brainstorm',
    onSelected: (bool selected) {
    setState(() {
    _selectedCategory = 'Brainstorm';
    });
    },
    ),
    ChoiceChip(
    label: const Text('Design'),
    selected: _selectedCategory == 'Design',
    onSelected: (bool selected) {
    setState(() {
    _selectedCategory = 'Design';
    });
    },
    ),
    ChoiceChip(
    label: const Text('Workout'),
    selected: _selectedCategory == 'Workout',
    onSelected: (bool selected) {
    setState(() {
    _selectedCategory = 'Workout';
    });
    },
    ),
    ],
    ),
    ],
    ),
    ),
    floatingActionButton: FloatingActionButton(
    child: const Icon(Icons.check),
    onPressed: () {
    if (_formKey.currentState!.validate()) {
    final event = Event(
    id: const Uuid().v4(),
    title: _titleController.text,
    description: _descriptionController.text.isEmpty
    ? null
        : _descriptionController.text,
    date: _selectedDate,
    startTime: _startTime,
    endTime: _endTime,
    category: _selectedCategory,
    isReminded: _remindMe,
    isCompleted: false,
    );
    context.read<CalendarCubit>().addEvent(event);
    Navigator.pop(context);
    }
    },
    ),
    );
  }
}
