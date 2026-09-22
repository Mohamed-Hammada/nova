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

@DriftDatabase(tables: [MasteryRecordRows, DimensionEstimateRows, GameRungState])
class NovaDatabase extends _$NovaDatabase {
  NovaDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
