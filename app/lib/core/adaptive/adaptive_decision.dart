class AdaptiveDecision {
  const AdaptiveDecision({required this.childId, required this.gameId, required this.nextRungId, required this.scaffold, required this.reason});

  final String childId;
  final String gameId;
  final String nextRungId;
  final String scaffold; // 'modelled' | 'guided' | 'hint_on_request' | 'independent'
  final String reason;
}
