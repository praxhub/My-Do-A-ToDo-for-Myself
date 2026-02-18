import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class DailyNote extends HiveObject {
  DailyNote({
    required this.id,
    required this.date,
    required this.content,
    this.imagePath,
    this.audioPath,
    required this.updatedAt,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String content;

  @HiveField(3)
  String? imagePath;

  @HiveField(4)
  String? audioPath;

  @HiveField(5)
  DateTime updatedAt;
}

class DailyNoteAdapter extends TypeAdapter<DailyNote> {
  @override
  final int typeId = 2;

  @override
  DailyNote read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return DailyNote(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      content: fields[2] as String,
      imagePath: fields[3] as String?,
      audioPath: fields[4] as String?,
      updatedAt: fields[5] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyNote obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.imagePath)
      ..writeByte(4)
      ..write(obj.audioPath)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }
}
