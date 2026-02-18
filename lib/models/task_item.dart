import 'package:hive/hive.dart';

@HiveType(typeId: 0)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 3)
enum TaskKind {
  @HiveField(0)
  todo,
  @HiveField(1)
  dayPlan,
}

@HiveType(typeId: 1)
class TaskItem extends HiveObject {
  TaskItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.imagePath,
    this.audioPath,
    this.kind = TaskKind.todo,
    this.completedAt,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  TaskPriority priority;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  String? imagePath;

  @HiveField(7)
  String? audioPath;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  TaskKind kind;

  @HiveField(10)
  DateTime? completedAt;
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 0;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.low:
        writer.writeByte(0);
      case TaskPriority.medium:
        writer.writeByte(1);
      case TaskPriority.high:
        writer.writeByte(2);
    }
  }
}

class TaskKindAdapter extends TypeAdapter<TaskKind> {
  @override
  final int typeId = 3;

  @override
  TaskKind read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskKind.todo;
      case 1:
        return TaskKind.dayPlan;
      default:
        return TaskKind.todo;
    }
  }

  @override
  void write(BinaryWriter writer, TaskKind obj) {
    switch (obj) {
      case TaskKind.todo:
        writer.writeByte(0);
      case TaskKind.dayPlan:
        writer.writeByte(1);
    }
  }
}

class TaskItemAdapter extends TypeAdapter<TaskItem> {
  @override
  final int typeId = 1;

  @override
  TaskItem read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    // Compatibility path:
    // - Stable format:
    //   5=isCompleted(bool), 6=imagePath, 7=audioPath, 8=createdAt, 9=kind, 10=completedAt
    // - Early v1.2 pre-release format:
    //   5=kind(TaskKind), 6=isCompleted(bool), 7=imagePath, 8=audioPath, 9=createdAt
    final field5 = fields[5];
    final isBrokenV12Shape = field5 is TaskKind;

    final isCompleted = isBrokenV12Shape
        ? (fields[6] as bool? ?? false)
        : (fields[5] as bool? ?? false);
    final completedAt = isBrokenV12Shape ? null : (fields[10] as DateTime?);

    return TaskItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      dueDate: fields[3] as DateTime?,
      priority: fields[4] as TaskPriority? ?? TaskPriority.medium,
      isCompleted: isCompleted,
      imagePath: isBrokenV12Shape ? fields[7] as String? : fields[6] as String?,
      audioPath: isBrokenV12Shape ? fields[8] as String? : fields[7] as String?,
      createdAt: isBrokenV12Shape
          ? (fields[9] as DateTime? ?? DateTime.now())
          : (fields[8] as DateTime? ?? DateTime.now()),
      kind: isBrokenV12Shape
          ? field5
          : (fields[9] as TaskKind? ?? TaskKind.todo),
      completedAt: isCompleted ? completedAt : null,
    );
  }

  @override
  void write(BinaryWriter writer, TaskItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.audioPath)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.kind)
      ..writeByte(10)
      ..write(obj.completedAt);
  }
}
