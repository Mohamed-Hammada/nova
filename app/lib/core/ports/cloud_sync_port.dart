/// Deliberately unimplemented in this plan and never wired at the
/// composition root (Task 15). Its presence here is what lets a future
/// sync adapter be added later without touching the domain core (design
/// doc 2026-09-22, section 21).
abstract class CloudSyncPort {
  Future<void> push(Map<String, dynamic> exportedProgress);
  Future<Map<String, dynamic>?> pull();
}
