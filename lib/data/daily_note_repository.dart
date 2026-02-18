import 'dart:io';

import '../models/daily_note.dart';
import 'app_database.dart';

class DailyNoteRepository {
  DailyNoteRepository._();

  static List<DailyNote> all() {
    final notes = AppDatabase.noteBox.values.toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

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
    note.updatedAt = DateTime.now();
    await AppDatabase.noteBox.put(note.id, note);
  }

  static Future<void> delete(DailyNote note) async {
    await _deleteFileIfExists(note.imagePath);
    await _deleteFileIfExists(note.audioPath);
    await AppDatabase.noteBox.delete(note.id);
  }

  static Future<void> clearAll() async {
    await AppDatabase.noteBox.clear();
  }

  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static Future<void> _deleteFileIfExists(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
