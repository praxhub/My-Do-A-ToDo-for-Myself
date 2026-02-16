import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaService {
  MediaService._();

  static const int maxCompressedImageBytes = 5 * 1024 * 1024;

  static Future<String?> pickAndSaveImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final targetPath = p.join(
      imagesDir.path,
      'img_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      targetPath,
      quality: 75,
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );

    final outputFile = compressed != null
        ? File(compressed.path)
        : File(picked.path);
    if (await outputFile.length() > maxCompressedImageBytes) {
      await outputFile.delete();
      return null;
    }

    return outputFile.path;
  }

  static Future<String> createAudioPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(appDir.path, 'audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return p.join(
      audioDir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
  }
}
