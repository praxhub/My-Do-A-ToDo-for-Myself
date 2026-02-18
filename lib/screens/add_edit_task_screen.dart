import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../data/task_repository.dart';
import '../models/task_item.dart';
import '../services/media_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  const AddEditTaskScreen({
    super.key,
    this.existingTask,
    this.initialDueDate,
    this.initialKind,
  });

  final TaskItem? existingTask;
  final DateTime? initialDueDate;
  final TaskKind? initialKind;

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  static const _maxRecordDuration = Duration(minutes: 5);

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  TaskKind _kind = TaskKind.todo;
  String? _imagePath;
  String? _audioPath;
  bool _isRecording = false;
  Duration _recordedDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _dueDate = task.dueDate;
      _priority = task.priority;
      _kind = task.kind;
      _imagePath = task.imagePath;
      _audioPath = task.audioPath;
    } else {
      _dueDate = widget.initialDueDate;
      _kind = widget.initialKind ?? TaskKind.todo;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );

    if (!mounted || selectedDate == null) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _dueDate == null
          ? TimeOfDay.fromDateTime(now)
          : TimeOfDay.fromDateTime(_dueDate!),
    );

    if (selectedTime == null) return;

    setState(() {
      _dueDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final path = await MediaService.pickAndSaveImage(source);
    if (!mounted) return;

    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image is too large after compression (max 5MB).'),
        ),
      );
      return;
    }

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
    if (path == null) return;
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(path));
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.existingTask;
    final task = TaskItem(
      id: existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      kind: _kind,
      isCompleted: existing?.isCompleted ?? false,
      imagePath: _imagePath,
      audioPath: _audioPath,
      createdAt: existing?.createdAt ?? DateTime.now(),
      completedAt: existing?.completedAt,
    );

    await TaskRepository.upsert(task);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dueLabel = _dueDate == null
        ? 'No due date'
        : DateFormat.yMMMd().add_jm().format(_dueDate!);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask == null ? 'Add Task' : 'Edit Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              autofocus: widget.existingTask != null,
              decoration: const InputDecoration(labelText: 'Task'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Task is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskPriority>(
              initialValue: _priority,
              items: TaskPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskKind>(
              initialValue: _kind,
              items: TaskKind.values
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(kind == TaskKind.todo ? 'ToDo' : 'Day Plan'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _kind = value);
                }
              },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Due: $dueLabel')),
                TextButton(onPressed: _pickDateTime, child: const Text('Pick')),
                TextButton(
                  onPressed: () => setState(() => _dueDate = null),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'Image Attachment',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_imagePath != null && File(_imagePath!).existsSync())
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _ImagePreviewScreen(imagePath: _imagePath!),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_imagePath!),
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                if (_imagePath != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _imagePath = null),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
            const Divider(),
            const Text(
              'Voice Note',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_isRecording)
              Text('Recording: ${_recordedDuration.inSeconds}s / 300s'),
            Wrap(
              spacing: 8,
              children: [
                if (!_isRecording)
                  ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.mic),
                    label: const Text('Record'),
                  ),
                if (_isRecording)
                  ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                if (_audioPath != null)
                  ElevatedButton.icon(
                    onPressed: _playAudio,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                  ),
                if (_audioPath != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _audioPath = null),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _saveTask, child: const Text('Save Task')),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  const _ImagePreviewScreen({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Image.file(File(imagePath))),
    );
  }
}
