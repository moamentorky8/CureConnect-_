import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/hexagon_background.dart';
import '../../../shared/data/cureconnect_repository.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, required this.user});

  final User user;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _sendingSos = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(deviceSnapshotProvider);
    final logs = ref.watch(logsProvider);

    return HexagonBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CureConnect',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Welcome back, ${widget.user.displayName ?? widget.user.email ?? 'operator'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(repositoryProvider).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            snapshot.when(
              data: (device) => Column(
                children: [
                  GlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(device.deviceName, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(
                                device.isOnline ? 'Online and synchronized' : 'Offline fail-safe mode',
                                style: TextStyle(
                                  color: device.isOnline ? AppColors.logoMint : Colors.orangeAccent,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Last sync ${DateFormat('MMM d, HH:mm').format(device.lastSync)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        _BatteryGauge(value: device.batteryPercent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dose State'),
                              const SizedBox(height: 8),
                              Text(
                                device.lastDoseState.toUpperCase(),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppColors.logoCyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Remote Trigger'),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: () => _openTriggerDialog(context),
                                icon: const Icon(Icons.lock_open_rounded),
                                label: const Text('Open Drawer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Device load error: $error'),
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency SOS',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This sends an emergency_status update to Firebase and plays a spoken ElevenLabs alert through the phone speaker.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    onPressed: _sendingSos ? null : _triggerSos,
                    icon: const Icon(Icons.warning_rounded),
                    label: Text(_sendingSos ? 'Sending...' : 'SOS'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Dose Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  logs.when(
                    data: (items) => Column(
                      children: items.take(5).map((log) {
                        final color = switch (log.status) {
                          'success' => AppColors.logoMint,
                          'missed' => Colors.orangeAccent,
                          _ => AppColors.logoCyan,
                        };
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(backgroundColor: color, radius: 8),
                          title: Text('Drawer ${log.drawer} - ${log.status.toUpperCase()}'),
                          subtitle: Text(
                            DateFormat('MMM d, HH:mm').format(log.loggedAt),
                          ),
                          trailing: Text('${log.batteryPercent.toStringAsFixed(0)}%'),
                        );
                      }).toList(),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Text('Log load error: $error'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTriggerDialog(BuildContext context) async {
    final controller = TextEditingController(text: '1');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remote Trigger'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Drawer number (1-10)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final drawer = int.tryParse(controller.text) ?? 1;
              await ref.read(repositoryProvider).triggerDrawer(defaultDeviceId, drawer);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSos() async {
    setState(() => _sendingSos = true);
    try {
      await ref.read(repositoryProvider).triggerEmergencyAlert();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS alert sent and emergency audio started.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SOS failed: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingSos = false);
      }
    }
  }
}

class _BatteryGauge extends StatelessWidget {
  const _BatteryGauge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0, 100);
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: safeValue / 100,
            strokeWidth: 9,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              safeValue > 30 ? AppColors.logoMint : Colors.orangeAccent,
            ),
          ),
          Center(
            child: Text(
              '${safeValue.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
