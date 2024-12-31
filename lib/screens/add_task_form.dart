import 'package:flutter/material.dart';
import '../models/event_model.dart';

class AddTaskForm extends StatefulWidget {
  final DateTime selectedDate;
  final ScrollController scrollController;

  const AddTaskForm({super.key, required this.selectedDate, required this.scrollController});

  @override
  AddTaskFormState createState() => AddTaskFormState();
}

class AddTaskFormState extends State<AddTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  String _selectedCategory = 'Brainstorm';
  String _urgency = 'Low';
  String _priority = 'Normal';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      lastDate: DateTime(2125),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text('Start Time: ${_startTime.format(context)}'),
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
                ListTile(
                  title: Text('End Time: ${_endTime?.format(context) ?? 'Not set'}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _endTime ?? _startTime,
                    );
                    if (picked != null) {
                      setState(() {
                        _endTime = picked;
                      });
                    }
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
                    ChoiceChip(
                      label: const Text('Add Category'),
                      selected: false,
                      onSelected: (bool selected) {
                        _showAddCategoryDialog(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                const Text('Select Urgency'),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ChoiceChip(
                      label: const Text('Low'),
                      selected: _urgency == 'Low',
                      onSelected: (bool selected) {
                        setState(() {
                          _urgency = 'Low';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Medium'),
                      selected: _urgency == 'Medium',
                      onSelected: (bool selected) {
                        setState(() {
                          _urgency = 'Medium';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('High'),
                      selected: _urgency == 'High',
                      onSelected: (bool selected) {
                        setState(() {
                          _urgency = 'High';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                const Text('Select Priority'),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ChoiceChip(
                      label: const Text('Low'),
                      selected: _priority == 'Low',
                      onSelected: (bool selected) {
                        setState(() {
                          _priority = 'Low';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Normal'),
                      selected: _priority == 'Normal',
                      onSelected: (bool selected) {
                        setState(() {
                          _priority = 'Normal';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('High'),
                      selected: _priority == 'High',
                      onSelected: (bool selected) {
                        setState(() {
                          _priority = 'High';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final startTime = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _startTime.hour,
                        _startTime.minute,
                      );
                      final endTime = _endTime != null
                          ? DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _endTime!.hour,
                        _endTime!.minute,
                      )
                          : startTime.add(Duration(minutes: 1));

                      if (endTime.isBefore(startTime)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('End time must be after start time')),
                        );
                        return;
                      }

                      final event = Event(
                        title: _titleController.text,
                        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                        startTime: startTime,
                        endTime: endTime,
                        category: _selectedCategory,
                      );
                      Navigator.pop(context, event);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: categoryController,
            decoration: const InputDecoration(
              labelText: 'Category name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = categoryController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
