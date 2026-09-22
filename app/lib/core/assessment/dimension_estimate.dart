class DimensionEstimate {
  const DimensionEstimate({
    required this.skillId,
    required this.dimension,
    required this.metrics,
    required this.evidenceCount,
    required this.lastUpdated,
  });

  final String skillId;
  final String dimension; // 'performance' | 'independence' | 'transfer'
  final Map<String, num> metrics;
  final int evidenceCount;
  final DateTime lastUpdated;
}
