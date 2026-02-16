import 'dart:io';

import '../models/daily_note.dart';
import 'app_database.dart';

class DailyNoteRepository {
  DailyNoteRepository._();

  static DailyNote? byDate(DateTime date) {
    final normalized = _normalize(date);
    for (final note in AppDatabase.noteBox.values) {
      final noteDate = _normalize(note.date);
      if (noteDate == normalized) {
        return note;
      }
    }
    return null;
  }

  static Future<void> upsert(DailyNote note) async {
    await AppDatabase.noteBox.put(note.id, note);
  }

  static Future<void> delete(DailyNote note) async {
    if (note.imagePath != null) {
      final file = File(note.imagePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await AppDatabase.noteBox.delete(note.id);
  }

  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
