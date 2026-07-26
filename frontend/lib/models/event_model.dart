import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String name;
  final DateTime date;
  final DateTime endDate;
  final String time;
  final int sessionCount;

  EventModel({
    required this.id,
    required this.name,
    required this.date,
    required this.endDate,
    required this.time,
    required this.sessionCount,
  });

  factory EventModel.fromMap(Map<String, dynamic> data, String documentId) {
    return EventModel(
      id: documentId,
      name: data['name'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['end_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: data['time'] ?? '',
      sessionCount: data['session_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'end_date': Timestamp.fromDate(endDate),
      'time': time,
      'session_count': sessionCount,
    };
  }

  EventModel copyWith({
    String? id,
    String? name,
    DateTime? date,
    DateTime? endDate,
    String? time,
    int? sessionCount,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      time: time ?? this.time,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }
}

// Dummy data for Landing Screen
final List<EventModel> dummyEvents = [
  EventModel(
    id: 'e1',
    name: 'Wedding of Budi & Siti',
    date: DateTime.now().subtract(const Duration(days: 2)), // Masa lalu
    endDate: DateTime.now().subtract(const Duration(days: 2)), 
    time: '08:00 - 15:00',
    sessionCount: 200,
  ),
  EventModel(
    id: 'e2',
    name: 'Graduation SMA Negeri 1',
    date: DateTime.now(), // Hari ini
    endDate: DateTime.now(), 
    time: '07:30', // Waktu mulai
    sessionCount: 350,
  ),
  EventModel(
    id: 'e3',
    name: 'Corporate Gathering Tech Corp',
    date: DateTime.now().add(const Duration(days: 3)), // Masa depan
    endDate: DateTime.now().add(const Duration(days: 5)), // Rentang 3 hari
    time: '18:00 - 22:00',
    sessionCount: 120,
  ),
];
