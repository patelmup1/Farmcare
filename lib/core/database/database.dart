import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// ignore: private_collision_in_mixin_application
part 'database.g.dart';

class Farms extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get userId => text().nullable()(); // Supabase User ID
  TextColumn get name => text()();
  TextColumn get cropType => text()();
  DateTimeColumn get plantingDate => dateTime()();
  RealColumn get area => real()();
  TextColumn get areaUnit => text()(); // acres, hectare
  
  // Sync Status
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()(); // Soft delete for sync

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get farmId => text().references(Farms, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text()(); // e.g., "10kg Urea"
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  
  // Sync Status
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Farms, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Stream<List<TypedResult>> watchTodaysTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = select(tasks).join([
      leftOuterJoin(farms, farms.id.equalsExp(tasks.farmId)),
    ])
    ..where(tasks.date.isBetweenValues(startOfDay, endOfDay))
    ..orderBy([OrderingTerm.asc(tasks.date)]);

    return query.watch();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
