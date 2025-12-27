import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers.dart';
import '../../../core/database/database.dart';
import '../../../../l10n/app_localizations.dart';
import 'import_schedule_screen.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final db = ref.watch(databaseProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.schedule ?? 'Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: l10n?.importSchedule ?? 'Import Schedule',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportScheduleScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: db.select(db.tasks).watch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
           if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return Center(child: Text(l10n?.noTasks ?? 'No tasks scheduled.'));
          }

          // Sort by date desc
          tasks.sort((a, b) => a.date.compareTo(b.date));

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isOverdue = task.date.isBefore(DateTime.now()) && !task.isCompleted;

              return CheckboxListTile(
                title: Text(
                  task.description,
                  style: TextStyle(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: isOverdue ? Colors.red : null,
                  ),
                ),
                subtitle: Text(DateFormat.yMMMd().format(task.date)),
                value: task.isCompleted,
                onChanged: (val) {
                   if (val == null) return;
                   // Update completion status
                   (db.update(db.tasks)..where((t) => t.id.equals(task.id)))
                     .write(TasksCompanion(
                       isCompleted: drift.Value(val),
                       isSynced: const drift.Value(false), // Mark dirty for sync
                       updatedAt: drift.Value(DateTime.now()),
                     ));
                },
                secondary: task.isSynced 
                   ? const Icon(Icons.cloud_done, size: 16, color: Colors.green)
                   : const Icon(Icons.cloud_upload, size: 16, color: Colors.grey),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.of(context).pushNamed('/add-task');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
