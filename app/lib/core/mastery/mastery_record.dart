class MasteryRecord {
  const MasteryRecord({required this.childId, required this.skillId, required this.state, required this.confidence, required this.updatedAt});

  final String childId;
  final String skillId;
  final String? state; // null = "Not yet" -- never a fifth string literal
  final double confidence;
  final DateTime updatedAt;
}
