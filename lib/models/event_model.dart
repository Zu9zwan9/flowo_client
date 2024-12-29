import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Event extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final String category;
  final bool isReminded;
  final bool isCompleted;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.category,
    this.isReminded = false,
    this.isCompleted = false,
  });

  Event copyWith({
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? category,
    bool? isReminded,
    bool? isCompleted,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      isReminded: isReminded ?? this.isReminded,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    date,
    startTime,
    endTime,
    category,
    isReminded,
    isCompleted,
  ];
}
