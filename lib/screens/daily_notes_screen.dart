import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../data/app_database.dart';
import '../data/daily_note_repository.dart';
import '../models/daily_note.dart';
import '../services/media_service.dart';

class DailyNotesScreen extends StatefulWidget {
  const DailyNotesScreen({super.key});

  @override
  State<DailyNotesScreen> createState() => _DailyNotesScreenState();
}

class _DailyNotesScreenState extends State<DailyNotesScreen> {
  static const _maxRecordDuration = Duration(minutes: 5);

  final _controller = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  DateTime _selectedDate = DateTime.now();
  DailyNote? _currentNote;
  String? _imagePath;
  String? _audioPath;
  bool _isRecording = false;
  Duration _recordedDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _loadForDate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _loadForDate() {
    final note = DailyNoteRepository.byDate(_selectedDate);
    setState(() {
      _currentNote = note;
      _controller.text = note?.content ?? '';
      _imagePath = note?.imagePath;
      _audioPath = note?.audioPath;
      _isRecording = false;
      _recordedDuration = Duration.zero;
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

  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) return;

    final outputPath = await MediaService.createAudioPath();
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: outputPath,
    );

    _recordTimer?.cancel();
    _recordedDuration = Duration.zero;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      setState(() => _recordedDuration += const Duration(seconds: 1));
      if (_recordedDuration >= _maxRecordDuration) {
        await _stopRecording();
      }
    });

    setState(() {
      _isRecording = true;
      _audioPath = outputPath;
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    await _audioRecorder.stop();
    if (!mounted) return;
    setState(() => _isRecording = false);
  }

  Future<void> _playAudio() async {
    final path = _audioPath;
    if (path == null || path.isEmpty) return;
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(path));
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _imagePath == null && _audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add text, image, or audio before saving.'),
        ),
      );
      return;
    }

    final existing = _currentNote;
    if (existing != null) {
      if (existing.imagePath != null && existing.imagePath != _imagePath) {
        final oldImage = File(existing.imagePath!);
        if (await oldImage.exists()) {
          await oldImage.delete();
        }
      }
      if (existing.audioPath != null && existing.audioPath != _audioPath) {
        final oldAudio = File(existing.audioPath!);
        if (await oldAudio.exists()) {
          await oldAudio.delete();
        }
      }
    }

    final note = DailyNote(
      id: existing?.id ?? const Uuid().v4(),
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      content: content,
      imagePath: _imagePath,
      audioPath: _audioPath,
      updatedAt: DateTime.now(),
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
    final selectedDateLabel = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return ValueListenableBuilder(
      valueListenable: AppDatabase.noteBox.listenable(),
      builder: (context, _, __) {
        final notes = DailyNoteRepository.all();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDateLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change Date'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              minLines: 8,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText: 'Write your journal entry...',
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
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Recording: ${_recordedDuration.inSeconds}s / 300s',
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                if (!_isRecording)
                  OutlinedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.mic),
                    label: const Text('Record'),
                  ),
                if (_isRecording)
                  OutlinedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                if (_audioPath != null)
                  OutlinedButton.icon(
                    onPressed: _playAudio,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play Audio'),
                  ),
                if (_audioPath != null)
                  TextButton(
                    onPressed: () => setState(() => _audioPath = null),
                    child: const Text('Remove audio'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: const Text('Save Entry')),
            if (_currentNote != null)
              TextButton(onPressed: _delete, child: const Text('Delete Entry')),
            const SizedBox(height: 20),
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (notes.isEmpty)
              const Text('No journal history yet.')
            else
              ...notes.map((note) {
                final dateLabel = DateFormat('yyyy-MM-dd').format(note.date);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(dateLabel),
                    subtitle: Text(
                      note.content.isEmpty ? '(No text)' : note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        if (note.imagePath != null)
                          const Icon(Icons.image, size: 18),
                        if (note.audioPath != null)
                          const Icon(Icons.mic, size: 18),
                      ],
                    ),
                    onTap: () {
                      setState(() => _selectedDate = note.date);
                      _loadForDate();
                    },
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
