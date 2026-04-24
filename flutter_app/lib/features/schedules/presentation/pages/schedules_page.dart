import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cureconnect/features/schedules/domain/entities/med_schedule.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/hexagon_background.dart';
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
                    'Schedule Manager',
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
            const SizedBox(height: 16),
            schedules.when(
              data: (items) => Column(
                children: items.map((schedule) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(schedule.label),
                        subtitle: Text(
                          'Drawer ${schedule.drawer} • ${schedule.time24h} • ${schedule.days.join(', ')}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _openEditor(context, ref, schedule: schedule);
                            } else if (value == 'delete') {
                              await ref
                                  .read(repositoryProvider)
                                  .deleteSchedule(defaultDeviceId, schedule.id);
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
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Schedule load error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {MedSchedule? schedule}) async {
    final labelController = TextEditingController(text: schedule?.label ?? '');
    final timeController = TextEditingController(text: schedule?.time24h ?? '08:00');
    final drawerController = TextEditingController(text: '${schedule?.drawer ?? 1}');
    final daysController = TextEditingController(
      text: schedule?.days.join(',') ?? 'Mon,Tue,Wed,Thu,Fri',
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule == null ? 'Add Schedule' : 'Edit Schedule'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Label')),
              const SizedBox(height: 12),
              TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Time (HH:mm)')),
              const SizedBox(height: 12),
              TextField(controller: drawerController, decoration: const InputDecoration(labelText: 'Drawer')),
              const SizedBox(height: 12),
              TextField(
                controller: daysController,
                decoration: const InputDecoration(labelText: 'Days comma-separated'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final item = MedSchedule(
                id: schedule?.id ?? FirebaseFirestore.instance.collection('_').doc().id,
                drawer: int.tryParse(drawerController.text) ?? 1,
                label: labelController.text.trim(),
                time24h: timeController.text.trim(),
                days: daysController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                enabled: true,
              );
              await ref.read(repositoryProvider).upsertSchedule(defaultDeviceId, item);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
