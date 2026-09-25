// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MasteryRecordRowsTable extends MasteryRecordRows
    with TableInfo<$MasteryRecordRowsTable, MasteryRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MasteryRecordRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skillIdMeta = const VerificationMeta(
    'skillId',
  );
  @override
  late final GeneratedColumn<String> skillId = GeneratedColumn<String>(
    'skill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    childId,
    skillId,
    state,
    confidence,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mastery_record_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<MasteryRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('skill_id')) {
      context.handle(
        _skillIdMeta,
        skillId.isAcceptableOrUnknown(data['skill_id']!, _skillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_skillIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_confidenceMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {childId, skillId};
  @override
  MasteryRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MasteryRecordRow(
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      skillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MasteryRecordRowsTable createAlias(String alias) {
    return $MasteryRecordRowsTable(attachedDatabase, alias);
  }
}

class MasteryRecordRow extends DataClass
    implements Insertable<MasteryRecordRow> {
  final String childId;
  final String skillId;
  final String? state;
  final double confidence;
  final DateTime updatedAt;
  const MasteryRecordRow({
    required this.childId,
    required this.skillId,
    this.state,
    required this.confidence,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['child_id'] = Variable<String>(childId);
    map['skill_id'] = Variable<String>(skillId);
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    map['confidence'] = Variable<double>(confidence);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MasteryRecordRowsCompanion toCompanion(bool nullToAbsent) {
    return MasteryRecordRowsCompanion(
      childId: Value(childId),
      skillId: Value(skillId),
      state: state == null && nullToAbsent
          ? const Value.absent()
          : Value(state),
      confidence: Value(confidence),
      updatedAt: Value(updatedAt),
    );
  }

  factory MasteryRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MasteryRecordRow(
      childId: serializer.fromJson<String>(json['childId']),
      skillId: serializer.fromJson<String>(json['skillId']),
      state: serializer.fromJson<String?>(json['state']),
      confidence: serializer.fromJson<double>(json['confidence']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'childId': serializer.toJson<String>(childId),
      'skillId': serializer.toJson<String>(skillId),
      'state': serializer.toJson<String?>(state),
      'confidence': serializer.toJson<double>(confidence),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MasteryRecordRow copyWith({
    String? childId,
    String? skillId,
    Value<String?> state = const Value.absent(),
    double? confidence,
    DateTime? updatedAt,
  }) => MasteryRecordRow(
    childId: childId ?? this.childId,
    skillId: skillId ?? this.skillId,
    state: state.present ? state.value : this.state,
    confidence: confidence ?? this.confidence,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MasteryRecordRow copyWithCompanion(MasteryRecordRowsCompanion data) {
    return MasteryRecordRow(
      childId: data.childId.present ? data.childId.value : this.childId,
      skillId: data.skillId.present ? data.skillId.value : this.skillId,
      state: data.state.present ? data.state.value : this.state,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MasteryRecordRow(')
          ..write('childId: $childId, ')
          ..write('skillId: $skillId, ')
          ..write('state: $state, ')
          ..write('confidence: $confidence, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(childId, skillId, state, confidence, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MasteryRecordRow &&
          other.childId == this.childId &&
          other.skillId == this.skillId &&
          other.state == this.state &&
          other.confidence == this.confidence &&
          other.updatedAt == this.updatedAt);
}

class MasteryRecordRowsCompanion extends UpdateCompanion<MasteryRecordRow> {
  final Value<String> childId;
  final Value<String> skillId;
  final Value<String?> state;
  final Value<double> confidence;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MasteryRecordRowsCompanion({
    this.childId = const Value.absent(),
    this.skillId = const Value.absent(),
    this.state = const Value.absent(),
    this.confidence = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MasteryRecordRowsCompanion.insert({
    required String childId,
    required String skillId,
    this.state = const Value.absent(),
    required double confidence,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : childId = Value(childId),
       skillId = Value(skillId),
       confidence = Value(confidence),
       updatedAt = Value(updatedAt);
  static Insertable<MasteryRecordRow> custom({
    Expression<String>? childId,
    Expression<String>? skillId,
    Expression<String>? state,
    Expression<double>? confidence,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (childId != null) 'child_id': childId,
      if (skillId != null) 'skill_id': skillId,
      if (state != null) 'state': state,
      if (confidence != null) 'confidence': confidence,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MasteryRecordRowsCompanion copyWith({
    Value<String>? childId,
    Value<String>? skillId,
    Value<String?>? state,
    Value<double>? confidence,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MasteryRecordRowsCompanion(
      childId: childId ?? this.childId,
      skillId: skillId ?? this.skillId,
      state: state ?? this.state,
      confidence: confidence ?? this.confidence,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (skillId.present) {
      map['skill_id'] = Variable<String>(skillId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MasteryRecordRowsCompanion(')
          ..write('childId: $childId, ')
          ..write('skillId: $skillId, ')
          ..write('state: $state, ')
          ..write('confidence: $confidence, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DimensionEstimateRowsTable extends DimensionEstimateRows
    with TableInfo<$DimensionEstimateRowsTable, DimensionEstimateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DimensionEstimateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skillIdMeta = const VerificationMeta(
    'skillId',
  );
  @override
  late final GeneratedColumn<String> skillId = GeneratedColumn<String>(
    'skill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dimensionMeta = const VerificationMeta(
    'dimension',
  );
  @override
  late final GeneratedColumn<String> dimension = GeneratedColumn<String>(
    'dimension',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricsJsonMeta = const VerificationMeta(
    'metricsJson',
  );
  @override
  late final GeneratedColumn<String> metricsJson = GeneratedColumn<String>(
    'metrics_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceCountMeta = const VerificationMeta(
    'evidenceCount',
  );
  @override
  late final GeneratedColumn<int> evidenceCount = GeneratedColumn<int>(
    'evidence_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    childId,
    skillId,
    dimension,
    metricsJson,
    evidenceCount,
    lastUpdated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dimension_estimate_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<DimensionEstimateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('skill_id')) {
      context.handle(
        _skillIdMeta,
        skillId.isAcceptableOrUnknown(data['skill_id']!, _skillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_skillIdMeta);
    }
    if (data.containsKey('dimension')) {
      context.handle(
        _dimensionMeta,
        dimension.isAcceptableOrUnknown(data['dimension']!, _dimensionMeta),
      );
    } else if (isInserting) {
      context.missing(_dimensionMeta);
    }
    if (data.containsKey('metrics_json')) {
      context.handle(
        _metricsJsonMeta,
        metricsJson.isAcceptableOrUnknown(
          data['metrics_json']!,
          _metricsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metricsJsonMeta);
    }
    if (data.containsKey('evidence_count')) {
      context.handle(
        _evidenceCountMeta,
        evidenceCount.isAcceptableOrUnknown(
          data['evidence_count']!,
          _evidenceCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceCountMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {childId, skillId, dimension};
  @override
  DimensionEstimateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DimensionEstimateRow(
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      skillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill_id'],
      )!,
      dimension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dimension'],
      )!,
      metricsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metrics_json'],
      )!,
      evidenceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}evidence_count'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      )!,
    );
  }

  @override
  $DimensionEstimateRowsTable createAlias(String alias) {
    return $DimensionEstimateRowsTable(attachedDatabase, alias);
  }
}

class DimensionEstimateRow extends DataClass
    implements Insertable<DimensionEstimateRow> {
  final String childId;
  final String skillId;
  final String dimension;
  final String metricsJson;
  final int evidenceCount;
  final DateTime lastUpdated;
  const DimensionEstimateRow({
    required this.childId,
    required this.skillId,
    required this.dimension,
    required this.metricsJson,
    required this.evidenceCount,
    required this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['child_id'] = Variable<String>(childId);
    map['skill_id'] = Variable<String>(skillId);
    map['dimension'] = Variable<String>(dimension);
    map['metrics_json'] = Variable<String>(metricsJson);
    map['evidence_count'] = Variable<int>(evidenceCount);
    map['last_updated'] = Variable<DateTime>(lastUpdated);
    return map;
  }

  DimensionEstimateRowsCompanion toCompanion(bool nullToAbsent) {
    return DimensionEstimateRowsCompanion(
      childId: Value(childId),
      skillId: Value(skillId),
      dimension: Value(dimension),
      metricsJson: Value(metricsJson),
      evidenceCount: Value(evidenceCount),
      lastUpdated: Value(lastUpdated),
    );
  }

  factory DimensionEstimateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DimensionEstimateRow(
      childId: serializer.fromJson<String>(json['childId']),
      skillId: serializer.fromJson<String>(json['skillId']),
      dimension: serializer.fromJson<String>(json['dimension']),
      metricsJson: serializer.fromJson<String>(json['metricsJson']),
      evidenceCount: serializer.fromJson<int>(json['evidenceCount']),
      lastUpdated: serializer.fromJson<DateTime>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'childId': serializer.toJson<String>(childId),
      'skillId': serializer.toJson<String>(skillId),
      'dimension': serializer.toJson<String>(dimension),
      'metricsJson': serializer.toJson<String>(metricsJson),
      'evidenceCount': serializer.toJson<int>(evidenceCount),
      'lastUpdated': serializer.toJson<DateTime>(lastUpdated),
    };
  }

  DimensionEstimateRow copyWith({
    String? childId,
    String? skillId,
    String? dimension,
    String? metricsJson,
    int? evidenceCount,
    DateTime? lastUpdated,
  }) => DimensionEstimateRow(
    childId: childId ?? this.childId,
    skillId: skillId ?? this.skillId,
    dimension: dimension ?? this.dimension,
    metricsJson: metricsJson ?? this.metricsJson,
    evidenceCount: evidenceCount ?? this.evidenceCount,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
  DimensionEstimateRow copyWithCompanion(DimensionEstimateRowsCompanion data) {
    return DimensionEstimateRow(
      childId: data.childId.present ? data.childId.value : this.childId,
      skillId: data.skillId.present ? data.skillId.value : this.skillId,
      dimension: data.dimension.present ? data.dimension.value : this.dimension,
      metricsJson: data.metricsJson.present
          ? data.metricsJson.value
          : this.metricsJson,
      evidenceCount: data.evidenceCount.present
          ? data.evidenceCount.value
          : this.evidenceCount,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DimensionEstimateRow(')
          ..write('childId: $childId, ')
          ..write('skillId: $skillId, ')
          ..write('dimension: $dimension, ')
          ..write('metricsJson: $metricsJson, ')
          ..write('evidenceCount: $evidenceCount, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    childId,
    skillId,
    dimension,
    metricsJson,
    evidenceCount,
    lastUpdated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DimensionEstimateRow &&
          other.childId == this.childId &&
          other.skillId == this.skillId &&
          other.dimension == this.dimension &&
          other.metricsJson == this.metricsJson &&
          other.evidenceCount == this.evidenceCount &&
          other.lastUpdated == this.lastUpdated);
}

class DimensionEstimateRowsCompanion
    extends UpdateCompanion<DimensionEstimateRow> {
  final Value<String> childId;
  final Value<String> skillId;
  final Value<String> dimension;
  final Value<String> metricsJson;
  final Value<int> evidenceCount;
  final Value<DateTime> lastUpdated;
  final Value<int> rowid;
  const DimensionEstimateRowsCompanion({
    this.childId = const Value.absent(),
    this.skillId = const Value.absent(),
    this.dimension = const Value.absent(),
    this.metricsJson = const Value.absent(),
    this.evidenceCount = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DimensionEstimateRowsCompanion.insert({
    required String childId,
    required String skillId,
    required String dimension,
    required String metricsJson,
    required int evidenceCount,
    required DateTime lastUpdated,
    this.rowid = const Value.absent(),
  }) : childId = Value(childId),
       skillId = Value(skillId),
       dimension = Value(dimension),
       metricsJson = Value(metricsJson),
       evidenceCount = Value(evidenceCount),
       lastUpdated = Value(lastUpdated);
  static Insertable<DimensionEstimateRow> custom({
    Expression<String>? childId,
    Expression<String>? skillId,
    Expression<String>? dimension,
    Expression<String>? metricsJson,
    Expression<int>? evidenceCount,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (childId != null) 'child_id': childId,
      if (skillId != null) 'skill_id': skillId,
      if (dimension != null) 'dimension': dimension,
      if (metricsJson != null) 'metrics_json': metricsJson,
      if (evidenceCount != null) 'evidence_count': evidenceCount,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DimensionEstimateRowsCompanion copyWith({
    Value<String>? childId,
    Value<String>? skillId,
    Value<String>? dimension,
    Value<String>? metricsJson,
    Value<int>? evidenceCount,
    Value<DateTime>? lastUpdated,
    Value<int>? rowid,
  }) {
    return DimensionEstimateRowsCompanion(
      childId: childId ?? this.childId,
      skillId: skillId ?? this.skillId,
      dimension: dimension ?? this.dimension,
      metricsJson: metricsJson ?? this.metricsJson,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (skillId.present) {
      map['skill_id'] = Variable<String>(skillId.value);
    }
    if (dimension.present) {
      map['dimension'] = Variable<String>(dimension.value);
    }
    if (metricsJson.present) {
      map['metrics_json'] = Variable<String>(metricsJson.value);
    }
    if (evidenceCount.present) {
      map['evidence_count'] = Variable<int>(evidenceCount.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DimensionEstimateRowsCompanion(')
          ..write('childId: $childId, ')
          ..write('skillId: $skillId, ')
          ..write('dimension: $dimension, ')
          ..write('metricsJson: $metricsJson, ')
          ..write('evidenceCount: $evidenceCount, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GameRungStateTable extends GameRungState
    with TableInfo<$GameRungStateTable, GameRungStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameRungStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rungIdMeta = const VerificationMeta('rungId');
  @override
  late final GeneratedColumn<String> rungId = GeneratedColumn<String>(
    'rung_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [childId, gameId, rungId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_rung_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameRungStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('rung_id')) {
      context.handle(
        _rungIdMeta,
        rungId.isAcceptableOrUnknown(data['rung_id']!, _rungIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rungIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {childId, gameId};
  @override
  GameRungStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameRungStateData(
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      rungId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rung_id'],
      )!,
    );
  }

  @override
  $GameRungStateTable createAlias(String alias) {
    return $GameRungStateTable(attachedDatabase, alias);
  }
}

class GameRungStateData extends DataClass
    implements Insertable<GameRungStateData> {
  final String childId;
  final String gameId;
  final String rungId;
  const GameRungStateData({
    required this.childId,
    required this.gameId,
    required this.rungId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['child_id'] = Variable<String>(childId);
    map['game_id'] = Variable<String>(gameId);
    map['rung_id'] = Variable<String>(rungId);
    return map;
  }

  GameRungStateCompanion toCompanion(bool nullToAbsent) {
    return GameRungStateCompanion(
      childId: Value(childId),
      gameId: Value(gameId),
      rungId: Value(rungId),
    );
  }

  factory GameRungStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameRungStateData(
      childId: serializer.fromJson<String>(json['childId']),
      gameId: serializer.fromJson<String>(json['gameId']),
      rungId: serializer.fromJson<String>(json['rungId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'childId': serializer.toJson<String>(childId),
      'gameId': serializer.toJson<String>(gameId),
      'rungId': serializer.toJson<String>(rungId),
    };
  }

  GameRungStateData copyWith({
    String? childId,
    String? gameId,
    String? rungId,
  }) => GameRungStateData(
    childId: childId ?? this.childId,
    gameId: gameId ?? this.gameId,
    rungId: rungId ?? this.rungId,
  );
  GameRungStateData copyWithCompanion(GameRungStateCompanion data) {
    return GameRungStateData(
      childId: data.childId.present ? data.childId.value : this.childId,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      rungId: data.rungId.present ? data.rungId.value : this.rungId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameRungStateData(')
          ..write('childId: $childId, ')
          ..write('gameId: $gameId, ')
          ..write('rungId: $rungId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(childId, gameId, rungId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameRungStateData &&
          other.childId == this.childId &&
          other.gameId == this.gameId &&
          other.rungId == this.rungId);
}

class GameRungStateCompanion extends UpdateCompanion<GameRungStateData> {
  final Value<String> childId;
  final Value<String> gameId;
  final Value<String> rungId;
  final Value<int> rowid;
  const GameRungStateCompanion({
    this.childId = const Value.absent(),
    this.gameId = const Value.absent(),
    this.rungId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameRungStateCompanion.insert({
    required String childId,
    required String gameId,
    required String rungId,
    this.rowid = const Value.absent(),
  }) : childId = Value(childId),
       gameId = Value(gameId),
       rungId = Value(rungId);
  static Insertable<GameRungStateData> custom({
    Expression<String>? childId,
    Expression<String>? gameId,
    Expression<String>? rungId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (childId != null) 'child_id': childId,
      if (gameId != null) 'game_id': gameId,
      if (rungId != null) 'rung_id': rungId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameRungStateCompanion copyWith({
    Value<String>? childId,
    Value<String>? gameId,
    Value<String>? rungId,
    Value<int>? rowid,
  }) {
    return GameRungStateCompanion(
      childId: childId ?? this.childId,
      gameId: gameId ?? this.gameId,
      rungId: rungId ?? this.rungId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (rungId.present) {
      map['rung_id'] = Variable<String>(rungId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameRungStateCompanion(')
          ..write('childId: $childId, ')
          ..write('gameId: $gameId, ')
          ..write('rungId: $rungId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LevelProgressRowsTable extends LevelProgressRows
    with TableInfo<$LevelProgressRowsTable, LevelProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LevelProgressRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<String> childId = GeneratedColumn<String>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelIdMeta = const VerificationMeta(
    'levelId',
  );
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
    'level_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [childId, levelId, stars, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'level_progress_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LevelProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('level_id')) {
      context.handle(
        _levelIdMeta,
        levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    } else if (isInserting) {
      context.missing(_starsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {childId, levelId};
  @override
  LevelProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LevelProgressRow(
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_id'],
      )!,
      levelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level_id'],
      )!,
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LevelProgressRowsTable createAlias(String alias) {
    return $LevelProgressRowsTable(attachedDatabase, alias);
  }
}

class LevelProgressRow extends DataClass
    implements Insertable<LevelProgressRow> {
  final String childId;
  final String levelId;
  final int stars;
  final DateTime updatedAt;
  const LevelProgressRow({
    required this.childId,
    required this.levelId,
    required this.stars,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['child_id'] = Variable<String>(childId);
    map['level_id'] = Variable<String>(levelId);
    map['stars'] = Variable<int>(stars);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LevelProgressRowsCompanion toCompanion(bool nullToAbsent) {
    return LevelProgressRowsCompanion(
      childId: Value(childId),
      levelId: Value(levelId),
      stars: Value(stars),
      updatedAt: Value(updatedAt),
    );
  }

  factory LevelProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LevelProgressRow(
      childId: serializer.fromJson<String>(json['childId']),
      levelId: serializer.fromJson<String>(json['levelId']),
      stars: serializer.fromJson<int>(json['stars']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'childId': serializer.toJson<String>(childId),
      'levelId': serializer.toJson<String>(levelId),
      'stars': serializer.toJson<int>(stars),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LevelProgressRow copyWith({
    String? childId,
    String? levelId,
    int? stars,
    DateTime? updatedAt,
  }) => LevelProgressRow(
    childId: childId ?? this.childId,
    levelId: levelId ?? this.levelId,
    stars: stars ?? this.stars,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LevelProgressRow copyWithCompanion(LevelProgressRowsCompanion data) {
    return LevelProgressRow(
      childId: data.childId.present ? data.childId.value : this.childId,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      stars: data.stars.present ? data.stars.value : this.stars,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LevelProgressRow(')
          ..write('childId: $childId, ')
          ..write('levelId: $levelId, ')
          ..write('stars: $stars, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(childId, levelId, stars, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LevelProgressRow &&
          other.childId == this.childId &&
          other.levelId == this.levelId &&
          other.stars == this.stars &&
          other.updatedAt == this.updatedAt);
}

class LevelProgressRowsCompanion extends UpdateCompanion<LevelProgressRow> {
  final Value<String> childId;
  final Value<String> levelId;
  final Value<int> stars;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LevelProgressRowsCompanion({
    this.childId = const Value.absent(),
    this.levelId = const Value.absent(),
    this.stars = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LevelProgressRowsCompanion.insert({
    required String childId,
    required String levelId,
    required int stars,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : childId = Value(childId),
       levelId = Value(levelId),
       stars = Value(stars),
       updatedAt = Value(updatedAt);
  static Insertable<LevelProgressRow> custom({
    Expression<String>? childId,
    Expression<String>? levelId,
    Expression<int>? stars,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (childId != null) 'child_id': childId,
      if (levelId != null) 'level_id': levelId,
      if (stars != null) 'stars': stars,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LevelProgressRowsCompanion copyWith({
    Value<String>? childId,
    Value<String>? levelId,
    Value<int>? stars,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LevelProgressRowsCompanion(
      childId: childId ?? this.childId,
      levelId: levelId ?? this.levelId,
      stars: stars ?? this.stars,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (childId.present) {
      map['child_id'] = Variable<String>(childId.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LevelProgressRowsCompanion(')
          ..write('childId: $childId, ')
          ..write('levelId: $levelId, ')
          ..write('stars: $stars, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingRowsTable extends SettingRows
    with TableInfo<$SettingRowsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingRowsTable createAlias(String alias) {
    return $SettingRowsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingRowsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingRowsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingRowsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$NovaDatabase extends GeneratedDatabase {
  _$NovaDatabase(QueryExecutor e) : super(e);
  $NovaDatabaseManager get managers => $NovaDatabaseManager(this);
  late final $MasteryRecordRowsTable masteryRecordRows =
      $MasteryRecordRowsTable(this);
  late final $DimensionEstimateRowsTable dimensionEstimateRows =
      $DimensionEstimateRowsTable(this);
  late final $GameRungStateTable gameRungState = $GameRungStateTable(this);
  late final $LevelProgressRowsTable levelProgressRows =
      $LevelProgressRowsTable(this);
  late final $SettingRowsTable settingRows = $SettingRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    masteryRecordRows,
    dimensionEstimateRows,
    gameRungState,
    levelProgressRows,
    settingRows,
  ];
}

typedef $$MasteryRecordRowsTableCreateCompanionBuilder =
    MasteryRecordRowsCompanion Function({
      required String childId,
      required String skillId,
      Value<String?> state,
      required double confidence,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MasteryRecordRowsTableUpdateCompanionBuilder =
    MasteryRecordRowsCompanion Function({
      Value<String> childId,
      Value<String> skillId,
      Value<String?> state,
      Value<double> confidence,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MasteryRecordRowsTableFilterComposer
    extends Composer<_$NovaDatabase, $MasteryRecordRowsTable> {
  $$MasteryRecordRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skillId => $composableBuilder(
    column: $table.skillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MasteryRecordRowsTableOrderingComposer
    extends Composer<_$NovaDatabase, $MasteryRecordRowsTable> {
  $$MasteryRecordRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skillId => $composableBuilder(
    column: $table.skillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MasteryRecordRowsTableAnnotationComposer
    extends Composer<_$NovaDatabase, $MasteryRecordRowsTable> {
  $$MasteryRecordRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get childId =>
      $composableBuilder(column: $table.childId, builder: (column) => column);

  GeneratedColumn<String> get skillId =>
      $composableBuilder(column: $table.skillId, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MasteryRecordRowsTableTableManager
    extends
        RootTableManager<
          _$NovaDatabase,
          $MasteryRecordRowsTable,
          MasteryRecordRow,
          $$MasteryRecordRowsTableFilterComposer,
          $$MasteryRecordRowsTableOrderingComposer,
          $$MasteryRecordRowsTableAnnotationComposer,
          $$MasteryRecordRowsTableCreateCompanionBuilder,
          $$MasteryRecordRowsTableUpdateCompanionBuilder,
          (
            MasteryRecordRow,
            BaseReferences<
              _$NovaDatabase,
              $MasteryRecordRowsTable,
              MasteryRecordRow
            >,
          ),
          MasteryRecordRow,
          PrefetchHooks Function()
        > {
  $$MasteryRecordRowsTableTableManager(
    _$NovaDatabase db,
    $MasteryRecordRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MasteryRecordRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MasteryRecordRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MasteryRecordRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> childId = const Value.absent(),
                Value<String> skillId = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MasteryRecordRowsCompanion(
                childId: childId,
                skillId: skillId,
                state: state,
                confidence: confidence,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String childId,
                required String skillId,
                Value<String?> state = const Value.absent(),
                required double confidence,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MasteryRecordRowsCompanion.insert(
                childId: childId,
                skillId: skillId,
                state: state,
                confidence: confidence,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MasteryRecordRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NovaDatabase,
      $MasteryRecordRowsTable,
      MasteryRecordRow,
      $$MasteryRecordRowsTableFilterComposer,
      $$MasteryRecordRowsTableOrderingComposer,
      $$MasteryRecordRowsTableAnnotationComposer,
      $$MasteryRecordRowsTableCreateCompanionBuilder,
      $$MasteryRecordRowsTableUpdateCompanionBuilder,
      (
        MasteryRecordRow,
        BaseReferences<
          _$NovaDatabase,
          $MasteryRecordRowsTable,
          MasteryRecordRow
        >,
      ),
      MasteryRecordRow,
      PrefetchHooks Function()
    >;
typedef $$DimensionEstimateRowsTableCreateCompanionBuilder =
    DimensionEstimateRowsCompanion Function({
      required String childId,
      required String skillId,
      required String dimension,
      required String metricsJson,
      required int evidenceCount,
      required DateTime lastUpdated,
      Value<int> rowid,
    });
typedef $$DimensionEstimateRowsTableUpdateCompanionBuilder =
    DimensionEstimateRowsCompanion Function({
      Value<String> childId,
      Value<String> skillId,
      Value<String> dimension,
      Value<String> metricsJson,
      Value<int> evidenceCount,
      Value<DateTime> lastUpdated,
      Value<int> rowid,
    });

class $$DimensionEstimateRowsTableFilterComposer
    extends Composer<_$NovaDatabase, $DimensionEstimateRowsTable> {
  $$DimensionEstimateRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skillId => $composableBuilder(
    column: $table.skillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dimension => $composableBuilder(
    column: $table.dimension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metricsJson => $composableBuilder(
    column: $table.metricsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get evidenceCount => $composableBuilder(
    column: $table.evidenceCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DimensionEstimateRowsTableOrderingComposer
    extends Composer<_$NovaDatabase, $DimensionEstimateRowsTable> {
  $$DimensionEstimateRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skillId => $composableBuilder(
    column: $table.skillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dimension => $composableBuilder(
    column: $table.dimension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricsJson => $composableBuilder(
    column: $table.metricsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get evidenceCount => $composableBuilder(
    column: $table.evidenceCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DimensionEstimateRowsTableAnnotationComposer
    extends Composer<_$NovaDatabase, $DimensionEstimateRowsTable> {
  $$DimensionEstimateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get childId =>
      $composableBuilder(column: $table.childId, builder: (column) => column);

  GeneratedColumn<String> get skillId =>
      $composableBuilder(column: $table.skillId, builder: (column) => column);

  GeneratedColumn<String> get dimension =>
      $composableBuilder(column: $table.dimension, builder: (column) => column);

  GeneratedColumn<String> get metricsJson => $composableBuilder(
    column: $table.metricsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get evidenceCount => $composableBuilder(
    column: $table.evidenceCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );
}

class $$DimensionEstimateRowsTableTableManager
    extends
        RootTableManager<
          _$NovaDatabase,
          $DimensionEstimateRowsTable,
          DimensionEstimateRow,
          $$DimensionEstimateRowsTableFilterComposer,
          $$DimensionEstimateRowsTableOrderingComposer,
          $$DimensionEstimateRowsTableAnnotationComposer,
          $$DimensionEstimateRowsTableCreateCompanionBuilder,
          $$DimensionEstimateRowsTableUpdateCompanionBuilder,
          (
            DimensionEstimateRow,
            BaseReferences<
              _$NovaDatabase,
              $DimensionEstimateRowsTable,
              DimensionEstimateRow
            >,
          ),
          DimensionEstimateRow,
          PrefetchHooks Function()
        > {
  $$DimensionEstimateRowsTableTableManager(
    _$NovaDatabase db,
    $DimensionEstimateRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DimensionEstimateRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DimensionEstimateRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DimensionEstimateRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> childId = const Value.absent(),
                Value<String> skillId = const Value.absent(),
                Value<String> dimension = const Value.absent(),
                Value<String> metricsJson = const Value.absent(),
                Value<int> evidenceCount = const Value.absent(),
                Value<DateTime> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DimensionEstimateRowsCompanion(
                childId: childId,
                skillId: skillId,
                dimension: dimension,
                metricsJson: metricsJson,
                evidenceCount: evidenceCount,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String childId,
                required String skillId,
                required String dimension,
                required String metricsJson,
                required int evidenceCount,
                required DateTime lastUpdated,
                Value<int> rowid = const Value.absent(),
              }) => DimensionEstimateRowsCompanion.insert(
                childId: childId,
                skillId: skillId,
                dimension: dimension,
                metricsJson: metricsJson,
                evidenceCount: evidenceCount,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DimensionEstimateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NovaDatabase,
      $DimensionEstimateRowsTable,
      DimensionEstimateRow,
      $$DimensionEstimateRowsTableFilterComposer,
      $$DimensionEstimateRowsTableOrderingComposer,
      $$DimensionEstimateRowsTableAnnotationComposer,
      $$DimensionEstimateRowsTableCreateCompanionBuilder,
      $$DimensionEstimateRowsTableUpdateCompanionBuilder,
      (
        DimensionEstimateRow,
        BaseReferences<
          _$NovaDatabase,
          $DimensionEstimateRowsTable,
          DimensionEstimateRow
        >,
      ),
      DimensionEstimateRow,
      PrefetchHooks Function()
    >;
typedef $$GameRungStateTableCreateCompanionBuilder =
    GameRungStateCompanion Function({
      required String childId,
      required String gameId,
      required String rungId,
      Value<int> rowid,
    });
typedef $$GameRungStateTableUpdateCompanionBuilder =
    GameRungStateCompanion Function({
      Value<String> childId,
      Value<String> gameId,
      Value<String> rungId,
      Value<int> rowid,
    });

class $$GameRungStateTableFilterComposer
    extends Composer<_$NovaDatabase, $GameRungStateTable> {
  $$GameRungStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rungId => $composableBuilder(
    column: $table.rungId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GameRungStateTableOrderingComposer
    extends Composer<_$NovaDatabase, $GameRungStateTable> {
  $$GameRungStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rungId => $composableBuilder(
    column: $table.rungId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GameRungStateTableAnnotationComposer
    extends Composer<_$NovaDatabase, $GameRungStateTable> {
  $$GameRungStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get childId =>
      $composableBuilder(column: $table.childId, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get rungId =>
      $composableBuilder(column: $table.rungId, builder: (column) => column);
}

class $$GameRungStateTableTableManager
    extends
        RootTableManager<
          _$NovaDatabase,
          $GameRungStateTable,
          GameRungStateData,
          $$GameRungStateTableFilterComposer,
          $$GameRungStateTableOrderingComposer,
          $$GameRungStateTableAnnotationComposer,
          $$GameRungStateTableCreateCompanionBuilder,
          $$GameRungStateTableUpdateCompanionBuilder,
          (
            GameRungStateData,
            BaseReferences<
              _$NovaDatabase,
              $GameRungStateTable,
              GameRungStateData
            >,
          ),
          GameRungStateData,
          PrefetchHooks Function()
        > {
  $$GameRungStateTableTableManager(_$NovaDatabase db, $GameRungStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameRungStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameRungStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameRungStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> childId = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> rungId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameRungStateCompanion(
                childId: childId,
                gameId: gameId,
                rungId: rungId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String childId,
                required String gameId,
                required String rungId,
                Value<int> rowid = const Value.absent(),
              }) => GameRungStateCompanion.insert(
                childId: childId,
                gameId: gameId,
                rungId: rungId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GameRungStateTableProcessedTableManager =
    ProcessedTableManager<
      _$NovaDatabase,
      $GameRungStateTable,
      GameRungStateData,
      $$GameRungStateTableFilterComposer,
      $$GameRungStateTableOrderingComposer,
      $$GameRungStateTableAnnotationComposer,
      $$GameRungStateTableCreateCompanionBuilder,
      $$GameRungStateTableUpdateCompanionBuilder,
      (
        GameRungStateData,
        BaseReferences<_$NovaDatabase, $GameRungStateTable, GameRungStateData>,
      ),
      GameRungStateData,
      PrefetchHooks Function()
    >;
typedef $$LevelProgressRowsTableCreateCompanionBuilder =
    LevelProgressRowsCompanion Function({
      required String childId,
      required String levelId,
      required int stars,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LevelProgressRowsTableUpdateCompanionBuilder =
    LevelProgressRowsCompanion Function({
      Value<String> childId,
      Value<String> levelId,
      Value<int> stars,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LevelProgressRowsTableFilterComposer
    extends Composer<_$NovaDatabase, $LevelProgressRowsTable> {
  $$LevelProgressRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LevelProgressRowsTableOrderingComposer
    extends Composer<_$NovaDatabase, $LevelProgressRowsTable> {
  $$LevelProgressRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LevelProgressRowsTableAnnotationComposer
    extends Composer<_$NovaDatabase, $LevelProgressRowsTable> {
  $$LevelProgressRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get childId =>
      $composableBuilder(column: $table.childId, builder: (column) => column);

  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LevelProgressRowsTableTableManager
    extends
        RootTableManager<
          _$NovaDatabase,
          $LevelProgressRowsTable,
          LevelProgressRow,
          $$LevelProgressRowsTableFilterComposer,
          $$LevelProgressRowsTableOrderingComposer,
          $$LevelProgressRowsTableAnnotationComposer,
          $$LevelProgressRowsTableCreateCompanionBuilder,
          $$LevelProgressRowsTableUpdateCompanionBuilder,
          (
            LevelProgressRow,
            BaseReferences<
              _$NovaDatabase,
              $LevelProgressRowsTable,
              LevelProgressRow
            >,
          ),
          LevelProgressRow,
          PrefetchHooks Function()
        > {
  $$LevelProgressRowsTableTableManager(
    _$NovaDatabase db,
    $LevelProgressRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LevelProgressRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LevelProgressRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LevelProgressRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> childId = const Value.absent(),
                Value<String> levelId = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LevelProgressRowsCompanion(
                childId: childId,
                levelId: levelId,
                stars: stars,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String childId,
                required String levelId,
                required int stars,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LevelProgressRowsCompanion.insert(
                childId: childId,
                levelId: levelId,
                stars: stars,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LevelProgressRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NovaDatabase,
      $LevelProgressRowsTable,
      LevelProgressRow,
      $$LevelProgressRowsTableFilterComposer,
      $$LevelProgressRowsTableOrderingComposer,
      $$LevelProgressRowsTableAnnotationComposer,
      $$LevelProgressRowsTableCreateCompanionBuilder,
      $$LevelProgressRowsTableUpdateCompanionBuilder,
      (
        LevelProgressRow,
        BaseReferences<
          _$NovaDatabase,
          $LevelProgressRowsTable,
          LevelProgressRow
        >,
      ),
      LevelProgressRow,
      PrefetchHooks Function()
    >;
typedef $$SettingRowsTableCreateCompanionBuilder =
    SettingRowsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingRowsTableUpdateCompanionBuilder =
    SettingRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingRowsTableFilterComposer
    extends Composer<_$NovaDatabase, $SettingRowsTable> {
  $$SettingRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingRowsTableOrderingComposer
    extends Composer<_$NovaDatabase, $SettingRowsTable> {
  $$SettingRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingRowsTableAnnotationComposer
    extends Composer<_$NovaDatabase, $SettingRowsTable> {
  $$SettingRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingRowsTableTableManager
    extends
        RootTableManager<
          _$NovaDatabase,
          $SettingRowsTable,
          SettingRow,
          $$SettingRowsTableFilterComposer,
          $$SettingRowsTableOrderingComposer,
          $$SettingRowsTableAnnotationComposer,
          $$SettingRowsTableCreateCompanionBuilder,
          $$SettingRowsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$NovaDatabase, $SettingRowsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingRowsTableTableManager(_$NovaDatabase db, $SettingRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$NovaDatabase,
      $SettingRowsTable,
      SettingRow,
      $$SettingRowsTableFilterComposer,
      $$SettingRowsTableOrderingComposer,
      $$SettingRowsTableAnnotationComposer,
      $$SettingRowsTableCreateCompanionBuilder,
      $$SettingRowsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$NovaDatabase, $SettingRowsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;

class $NovaDatabaseManager {
  final _$NovaDatabase _db;
  $NovaDatabaseManager(this._db);
  $$MasteryRecordRowsTableTableManager get masteryRecordRows =>
      $$MasteryRecordRowsTableTableManager(_db, _db.masteryRecordRows);
  $$DimensionEstimateRowsTableTableManager get dimensionEstimateRows =>
      $$DimensionEstimateRowsTableTableManager(_db, _db.dimensionEstimateRows);
  $$GameRungStateTableTableManager get gameRungState =>
      $$GameRungStateTableTableManager(_db, _db.gameRungState);
  $$LevelProgressRowsTableTableManager get levelProgressRows =>
      $$LevelProgressRowsTableTableManager(_db, _db.levelProgressRows);
  $$SettingRowsTableTableManager get settingRows =>
      $$SettingRowsTableTableManager(_db, _db.settingRows);
}
