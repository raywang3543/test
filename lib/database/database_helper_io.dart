import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// IO 平台（Android/iOS/macOS/Windows/Linux）数据库初始化
void initDatabasePlatform() {
  // IO 平台使用默认实现，不需要额外配置
}

/// IO 平台专用：确保数据库已准备好
Future<void> ensureDatabaseReady() async {
  // IO 平台不需要额外等待
}

/// IO 平台专用：获取数据库路径
Future<String?> getDatabasePath(String dbName) async {
  final databasesPath = await getDatabasesPath();
  return join(databasesPath, dbName);
}

/// IO 平台专用：打开数据库
Future<Database> openDatabaseForPlatform(
  String dbName, {
  required int version,
  required Future<void> Function(Database db, int version) onCreate,
  Future<void> Function(Database db, int oldVersion, int newVersion)? onUpgrade,
}) async {
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, dbName);

  return await openDatabase(
    path,
    version: version,
    onCreate: onCreate,
    onUpgrade: onUpgrade,
  );
}
