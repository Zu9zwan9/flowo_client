import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/event_model.dart';
import '../blocs/calendar/calendar_cubit.dart';

class EventFormDialog extends StatefulWidget {
  const EventFormDialog({super.key});

  @override
  EventFormDialogState createState() => EventFormDialogState();
}

class EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  String? _description;
  late DateTime _startTime;
  late DateTime _endTime;
  String _selectedCategory = 'Brainstorm';
  final String _urgency = 'Low';
  final String _priority = 'Normal';

  @override
  void initState() {
    super.initState();
    _title = '';
    _description = '';
    _startTime = DateTime.now();
    _endTime = DateTime.now().add(Duration(hours: 1));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      builder: (context, scrollController) {
        return Material(
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                      onSaved: (value) {
                        _title = value!;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      onSaved: (value) {
                        _description = value;
                      },
                    ),
                    const SizedBox(height: 16.0),
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
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          final event = Event(
                            title: _title,
                            description: _description,
                            startTime: _startTime,
                            endTime: _endTime,
                            category: _selectedCategory,
                          );
                          context.read<CalendarCubit>().addEvent(event);
                          Navigator.pop(context);
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
      },
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
