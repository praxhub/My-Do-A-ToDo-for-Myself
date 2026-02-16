import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../data/daily_note_repository.dart';
import '../models/daily_note.dart';
import '../services/media_service.dart';

class DailyNotesScreen extends StatefulWidget {
  const DailyNotesScreen({super.key});

  @override
  State<DailyNotesScreen> createState() => _DailyNotesScreenState();
}

class _DailyNotesScreenState extends State<DailyNotesScreen> {
  final _controller = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DailyNote? _currentNote;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadForDate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadForDate() {
    final note = DailyNoteRepository.byDate(_selectedDate);
    setState(() {
      _currentNote = note;
      _controller.text = note?.content ?? '';
      _imagePath = note?.imagePath;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _loadForDate();
  }

  Future<void> _pickImage(ImageSource source) async {
    final path = await MediaService.pickAndSaveImage(source);
    if (path == null || !mounted) return;
    setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text or image before saving.')),
      );
      return;
    }

    final note = DailyNote(
      id: _currentNote?.id ?? const Uuid().v4(),
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      content: content,
      imagePath: _imagePath,
    );

    await DailyNoteRepository.upsert(note);
    _loadForDate();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  Future<void> _delete() async {
    if (_currentNote == null) return;
    await DailyNoteRepository.delete(_currentNote!);
    _loadForDate();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(onPressed: _pickDate, child: const Text('Change Date')),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          minLines: 8,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'Write your daily note...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (_imagePath != null && File(_imagePath!).existsSync())
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_imagePath!),
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            if (_imagePath != null)
              TextButton(
                onPressed: () => setState(() => _imagePath = null),
                child: const Text('Remove image'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Save Entry')),
        if (_currentNote != null)
          TextButton(onPressed: _delete, child: const Text('Delete Entry')),
      ],
    );
  }
}
