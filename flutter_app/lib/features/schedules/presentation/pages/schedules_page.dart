import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/hexagon_background.dart';
import '../../domain/entities/med_schedule.dart';
import '../../../shared/data/cureconnect_repository.dart';

class SchedulesPage extends ConsumerWidget {
  const SchedulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(schedulesProvider);

    return HexagonBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Medication Schedules',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openEditor(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Each save updates Firebase Realtime Database and rebuilds the device-ready schedule.json payload.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 16),
            schedules.when(
              data: (items) {
                if (items.isEmpty) {
                  return const GlassCard(
                    child: Text('No reminders yet. Add the first medication schedule to sync with the ESP32.'),
                  );
                }

                return Column(
                  children: items.map((schedule) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(schedule.medicationName),
                          subtitle: Text('${schedule.dosage} - ${schedule.time24h}'),
                          trailing: PopupMenuButton<String>(
                            color: AppColors.surface,
                            onSelected: (value) async {
                              if (value == 'edit') {
                                _openEditor(context, ref, schedule: schedule);
                              } else if (value == 'delete') {
                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) {
                                  return;
                                }
                                await ref.read(repositoryProvider).deleteSchedule(uid, schedule.id);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Schedule load error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    MedSchedule? schedule,
  }) async {
    final medicationController = TextEditingController(text: schedule?.medicationName ?? '');
    final dosageController = TextEditingController(text: schedule?.dosage ?? '');
    TimeOfDay selectedTime = _parseTime(schedule?.time24h ?? '08:00');
    String timeText = _formatTime(selectedTime);
    final timeController = TextEditingController(text: timeText);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: dialogContext,
              initialTime: selectedTime,
            );
            if (picked != null) {
              selectedTime = picked;
              timeText = _formatTime(picked);
              timeController.text = timeText;
              setState(() => errorText = null);
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(schedule == null ? 'Add Reminder' : 'Edit Reminder'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: medicationController,
                    decoration: const InputDecoration(labelText: 'Medication Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageController,
                    decoration: const InputDecoration(labelText: 'Dosage'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeController,
                    readOnly: true,
                    onTap: pickTime,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      suffixIcon: Icon(Icons.access_time_rounded),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) {
                    setState(() => errorText = 'Please sign in again before editing schedules.');
                    return;
                  }

                  if (medicationController.text.trim().isEmpty ||
                      dosageController.text.trim().isEmpty) {
                    setState(() => errorText = 'Medication name and dosage are required.');
                    return;
                  }

                  final item = MedSchedule.create(
                    id: schedule?.id ?? FirebaseDatabase.instance.ref().push().key ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    medicationName: medicationController.text.trim(),
                    dosage: dosageController.text.trim(),
                    time24h: timeText,
                    enabled: true,
                    drawerIndex: schedule?.drawerIndex,
                  );

                  await ref.read(repositoryProvider).upsertSchedule(uid, item);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts.first) ?? 8 : 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
