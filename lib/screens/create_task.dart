// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flowo_client/blocs/create_task/task_cubit.dart';
// import 'package:flowo_client/models/category.dart';
//
// class CreateTaskPage extends StatefulWidget {
//   const CreateTaskPage({super.key});
//
//   @override
//   _CreateTaskPageState createState() => _CreateTaskPageState();
// }
//
// class _CreateTaskPageState extends State<CreateTaskPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _priorityController = TextEditingController();
//   final _estimatedTimeController = TextEditingController();
//   final _notesController = TextEditingController();
//   final _categoryController = TextEditingController();
//   DateTime? _selectedDate;
//   Duration? _selectedTime;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Create Task'),
//       ),
//       body: BlocListener<CreateTaskCubit, CreateTaskState>(
//         listener: (context, state) {
//           if (state is CreateTaskSuccess) {
//             Navigator.pop(context, state.task);
//           }
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   TextFormField(
//                     controller: _titleController,
//                     decoration: InputDecoration(labelText: 'Title'),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a title';
//                       }
//                       return null;
//                     },
//                   ),
//                   TextFormField(
//                     controller: _priorityController,
//                     decoration: InputDecoration(labelText: 'Priority'),
//                     keyboardType: TextInputType.number,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a priority';
//                       }
//                       return null;
//                     },
//                   ),
//                   TextFormField(
//                     controller: _estimatedTimeController,
//                     decoration: InputDecoration(
//                         labelText: 'Estimated Time (milliseconds)'),
//                     keyboardType: TextInputType.number,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter an estimated time';
//                       }
//                       return null;
//                     },
//                   ),
//                   ListTile(
//                     title: Text(_selectedDate == null
//                         ? 'Select Deadline Date'
//                         : 'Deadline Date: ${_selectedDate!.toLocal()}'
//                             .split(' ')[0]),
//                     trailing: Icon(Icons.calendar_today),
//                     onTap: () async {
//                       showCupertinoModalPopup(
//                         context: context,
//                         builder: (_) => SingleChildScrollView(
//                           child: Container(
//                             height: 250,
//                             color: Color.fromARGB(255, 255, 255, 255),
//                             child: Column(
//                               children: [
//                                 SizedBox(
//                                   height: 190,
//                                   child: CupertinoDatePicker(
//                                     mode: CupertinoDatePickerMode.date,
//                                     initialDateTime: DateTime.now(),
//                                     onDateTimeChanged: (val) {
//                                       setState(() {
//                                         _selectedDate = val;
//                                       });
//                                     },
//                                   ),
//                                 ),
//                                 CupertinoButton(
//                                   child: Text('OK'),
//                                   onPressed: () => Navigator.of(context).pop(),
//                                 )
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                   ListTile(
//                     title: Text(_selectedTime == null
//                         ? 'Select Deadline Time'
//                         : 'Deadline Time: ${_selectedTime!.inHours}:${_selectedTime!.inMinutes % 60}'),
//                     trailing: Icon(Icons.access_time),
//                     onTap: () async {
//                       showCupertinoModalPopup(
//                         context: context,
//                         builder: (_) => SingleChildScrollView(
//                           child: Container(
//                             height: 250,
//                             color: Color.fromARGB(255, 255, 255, 255),
//                             child: Column(
//                               children: [
//                                 SizedBox(
//                                   height: 200,
//                                   child: CupertinoTimerPicker(
//                                     mode: CupertinoTimerPickerMode.hm,
//                                     initialTimerDuration: Duration(),
//                                     onTimerDurationChanged: (val) {
//                                       setState(() {
//                                         _selectedTime = val;
//                                       });
//                                     },
//                                   ),
//                                 ),
//                                 CupertinoButton(
//                                   child: Text('OK'),
//                                   onPressed: () => Navigator.of(context).pop(),
//                                 )
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                   TextFormField(
//                     controller: _notesController,
//                     decoration: InputDecoration(labelText: 'Notes'),
//                     maxLines: 3,
//                   ),
//                   TextFormField(
//                     controller: _categoryController,
//                     decoration: InputDecoration(labelText: 'Category'),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a category';
//                       }
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       if (_formKey.currentState!.validate()) {
//                         final title = _titleController.text;
//                         final priority = int.parse(_priorityController.text);
//                         final notes = _notesController.text;
//                         final category =
//                             Category(name: _categoryController.text);
//
//                         final deadline = DateTime(
//                           _selectedDate!.year,
//                           _selectedDate!.month,
//                           _selectedDate!.day,
//                           _selectedTime!.inHours,
//                           _selectedTime!.inMinutes % 60,
//                         ).millisecondsSinceEpoch;
//
//                         context.read<CreateTaskCubit>().createTask(
//                               _titleController.text,
//                               int.parse(_priorityController.text),
//                               deadline,
//                               int.parse(_estimatedTimeController.text),
//                               _categoryController.text
//                                   as Category, // TODO: Fix this
//                               _notesController.text,
//                             );
//                       }
//                     },
//                     child: Text('Create Task'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
