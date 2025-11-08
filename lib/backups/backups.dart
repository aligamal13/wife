import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wife_flutter/DatabaseHelper/DatabaseHelper.dart';

class BackupManager {
final DatabaseHelper dbHelper;

BackupManager(this.dbHelper);

Future<void> backupData(String backupName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups/$backupName');
    await backupDir.create(recursive: true);

    final jsonData = await dbHelper.exportToJson();

    // Compress the JSON data
    final List<int> jsonBytes = utf8.encode(jsonData);
    final List<int> compressedData = GZipEncoder().encode(jsonBytes)!;

    // Save compressed data with dynamic name
    final compressedFile = File('${backupDir.path}/$backupName.gz');
    await compressedFile.writeAsBytes(compressedData);

    // Share the backup file
    await Share.shareXFiles([XFile(compressedFile.path)],
        text: 'نسخة احتياطية من التطبيق: $backupName');
  } catch (e) {
    throw Exception('فشل في إنشاء النسخة الاحتياطية: $e');
  }
}

Future<void> restoreFromBackup(String backupName) async {
try {
final directory = await getApplicationDocumentsDirectory();
final backupDir = Directory('${directory.path}/backups/$backupName');
// final compressedFile = File('${backupDir.path}/data.gz');


  final compressedFile = File('${backupDir.path}/$backupName.gz');

  if (await compressedFile.exists()) {
// Read and decompress the data
final List<int> compressedData = await compressedFile.readAsBytes();
final List<int> decompressedBytes =
GZipDecoder().decodeBytes(compressedData);
final jsonData = utf8.decode(decompressedBytes);

await dbHelper.importFromJson(jsonData);
} else {
throw Exception('النسخة الاحتياطية غير موجودة');
}
} catch (e) {
throw Exception('فشل في استعادة النسخة الاحتياطية: $e');
}
}

Future<void> restoreFromExternalFile(String filePath) async {
try {
final file = File(filePath);
if (await file.exists()) {
final List<int> compressedData = await file.readAsBytes();
final List<int> decompressedBytes =
GZipDecoder().decodeBytes(compressedData);
final jsonData = utf8.decode(decompressedBytes);

await dbHelper.importFromJson(jsonData);
} else {
throw Exception('الملف غير موجود');
}
} catch (e) {
throw Exception('فشل في استعادة البيانات من الملف الخارجي: $e');
}
}

Future<List<String>> getBackupsList() async {
try {
final directory = await getApplicationDocumentsDirectory();
final backupsDir = Directory('${directory.path}/backups');
if (!await backupsDir.exists()) {
return [];
}
final directories = await backupsDir
    .list()
    .where((entity) => entity is Directory)
    .toList();
return directories.map((dir) => path.basename(dir.path)).toList();
} catch (e) {
throw Exception('فشل في استرداد قائمة النسخ الاحتياطية: $e');
}
}
}