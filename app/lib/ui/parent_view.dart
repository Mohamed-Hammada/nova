import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_app/core/mastery/mastery_record.dart';
import 'package:nova_app/providers.dart';

class ParentView extends ConsumerWidget {
  const ParentView({super.key, required this.skillId});
  final String skillId;

  String _label(String? state) => switch (state) {
        null => 'Not yet',
        'emerging' => 'Emerging',
        'developing' => 'Developing',
        'secure' => 'Secure',
        'transfer' => 'Transfer',
        _ => 'Unknown',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: FutureBuilder<MasteryRecord?>(
        future: ref.watch(persistencePortProvider).currentMastery(childId: currentChildId, skillId: skillId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final record = snapshot.data;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_label(record?.state), style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                // This is an early, provisional estimate -- not a diagnosis
                // (curriculum spec section 3.5/3.6: every threshold behind
                // this is provisional, and Nova's claims are non-clinical).
                const Text('This is an early estimate, not a diagnosis.'),
              ],
            ),
          );
        },
      ),
    );
  }
}
