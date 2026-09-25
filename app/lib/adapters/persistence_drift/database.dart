import 'package:drift/drift.dart';

part 'database.g.dart';

// Table class names deliberately avoid drift's default singularized row-class
// names ("MasteryRecord", "DimensionEstimate") colliding with our own domain
// classes of those names (core/mastery/mastery_record.dart,
// core/assessment/dimension_estimate.dart) -- drift auto-generates a row
// data class per table (e.g. MasteryRecordRows -> MasteryRecordRow), and
// importing both this file and the domain files unprefixed into the same
// adapter file must not produce an ambiguous-import error.
class MasteryRecordRows extends Table {
  TextColumn get childId => text()();
  TextColumn get skillId => text()();
  TextColumn get state => text().nullable()();
  RealColumn get confidence => real()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {childId, skillId};
}

class DimensionEstimateRows extends Table {
  TextColumn get childId => text()();
  TextColumn get skillId => text()();
  TextColumn get dimension => text()();
  TextColumn get metricsJson => text()();
  IntColumn get evidenceCount => integer()();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {childId, skillId, dimension};
}

class GameRungState extends Table {
  TextColumn get childId => text()();
  TextColumn get gameId => text()();
  TextColumn get rungId => text()();

  @override
  Set<Column> get primaryKey => {childId, gameId};
}

/// Stars earned on each journey level. Presentation state only: stars are an
/// engagement reward (data/signals.yaml) and never feed mastery.
class LevelProgressRows extends Table {
  TextColumn get childId => text()();
  TextColumn get levelId => text()();
  IntColumn get stars => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {childId, levelId};
}

/// Per-device settings: age group, language, and the grown-up's choices for
/// voice, microphone and camera.
class SettingRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [MasteryRecordRows, DimensionEstimateRows, GameRungState, LevelProgressRows, SettingRows])
class NovaDatabase extends _$NovaDatabase {
  NovaDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(levelProgressRows);
            await m.createTable(settingRows);
          }
        },
      );
}
