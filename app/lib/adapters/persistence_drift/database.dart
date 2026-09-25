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

  /// The scaffold the Adaptive Engine chose with the rung (schema v4).
  TextColumn get scaffold => text().nullable()();

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

/// One row per child and journey activity: when it was first started and
/// finished, how often it was played and finished, and the best stars.
/// Rows are updated, never deleted, so history survives age changes.
class ActivityRecordRows extends Table {
  TextColumn get childId => text()();
  TextColumn get activityId => text()();
  DateTimeColumn get firstStartedAt => dateTime()();
  DateTimeColumn get lastPlayedAt => dateTime()();
  DateTimeColumn get firstCompletedAt => dateTime().nullable()();
  IntColumn get attempts => integer()();
  IntColumn get completions => integer()();
  IntColumn get bestStars => integer()();
  RealColumn get lastAccuracy => real().nullable()();

  /// How the last session went, from the assessment and adaptive pipeline
  /// (schema v4): hints per round, and the adaptive move and scaffold.
  RealColumn get lastHintsPerTrial => real().nullable()();
  TextColumn get lastMove => text().nullable()();
  TextColumn get lastScaffold => text().nullable()();

  @override
  Set<Column> get primaryKey => {childId, activityId};
}

/// Per-device settings: age group, language, and the grown-up's choices for
/// voice, microphone and camera.
class SettingRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [MasteryRecordRows, DimensionEstimateRows, GameRungState, LevelProgressRows, SettingRows, ActivityRecordRows])
class NovaDatabase extends _$NovaDatabase {
  NovaDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(levelProgressRows);
            await m.createTable(settingRows);
          }
          if (from < 3) {
            await m.createTable(activityRecordRows);
            // Levels finished before activity records existed become
            // completed records, so no child loses their journey history.
            await customStatement(
              'INSERT OR IGNORE INTO activity_record_rows '
              '(child_id, activity_id, first_started_at, last_played_at, first_completed_at, attempts, completions, best_stars) '
              'SELECT child_id, level_id, updated_at, updated_at, updated_at, 1, 1, stars FROM level_progress_rows',
            );
          }
          if (from >= 3 && from < 4) {
            await m.addColumn(activityRecordRows, activityRecordRows.lastHintsPerTrial);
            await m.addColumn(activityRecordRows, activityRecordRows.lastMove);
            await m.addColumn(activityRecordRows, activityRecordRows.lastScaffold);
          }
          if (from < 4) {
            await m.addColumn(gameRungState, gameRungState.scaffold);
          }
        },
      );
}
