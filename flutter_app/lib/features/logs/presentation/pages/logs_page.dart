import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/hexagon_background.dart';
import '../../../shared/data/cureconnect_repository.dart';

class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider);

    return HexagonBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Dose Activity',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: logs.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('No activity has been synced yet.');
                  }

                  return Column(
                    children: items.map((log) {
                      final color = switch (log.status) {
                        'success' => AppColors.logoMint,
                        'missed' => Colors.orangeAccent,
                        _ => AppColors.logoCyan,
                      };

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: color,
                          radius: 8,
                        ),
                        title: Text('Drawer ${log.drawer} - ${log.status.toUpperCase()}'),
                        subtitle: Text(
                          DateFormat('MMM d, HH:mm').format(log.loggedAt),
                        ),
                        trailing: Text('${log.batteryPercent.toStringAsFixed(0)}%'),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Log load error: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
