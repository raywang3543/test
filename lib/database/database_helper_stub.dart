import 'package:sqflite/sqflite.dart';

/// 平台初始化存根（当没有匹配的平台时使用）
void initDatabasePlatform() {
  // 默认实现，不做任何事
}

/// 存根：确保数据库已准备好
Future<void> ensureDatabaseReady() async {
  // 默认实现，不做任何事
}

/// 存根：获取数据库路径
Future<String?> getDatabasePath(String dbName) async {
  throw UnsupportedError('Platform not supported');
}

/// 存根：打开数据库
Future<Database> openDatabaseForPlatform(
  String dbName, {
  required int version,
  required Future<void> Function(Database db, int version) onCreate,
  Future<void> Function(Database db, int oldVersion, int newVersion)? onUpgrade,
}) async {
  throw UnsupportedError('Platform not supported');
}
