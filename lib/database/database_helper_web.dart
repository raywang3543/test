import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web 平台数据库初始化
void initDatabasePlatform() {
  // 设置 Web 数据库工厂
  databaseFactory = databaseFactoryFfiWeb;
}

/// Web 平台专用：确保数据库已准备好
Future<void> ensureDatabaseReady() async {
  // Web 平台不需要额外等待
}

/// Web 平台专用：打开数据库
/// 在 Web 平台上使用数据库工厂直接打开，不需要路径
Future<Database> openDatabaseForPlatform(
  String dbName, {
  required int version,
  required Future<void> Function(Database db, int version) onCreate,
  Future<void> Function(Database db, int oldVersion, int newVersion)? onUpgrade,
}) async {
  // Web 平台使用数据库名直接打开，存储在 IndexedDB 中
  return await openDatabase(
    dbName,
    version: version,
    onCreate: onCreate,
    onUpgrade: onUpgrade,
  );
}

/// Web 平台专用：获取数据库路径（返回 null，Web 平台不需要路径）
Future<String?> getDatabasePath(String dbName) async {
  // Web 平台不使用文件路径
  return null;
}
