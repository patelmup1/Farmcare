import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/providers.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/notification_service.dart';
import '../data/file_import_service.dart';

class ImportScheduleScreen extends ConsumerStatefulWidget {
  const ImportScheduleScreen({super.key});

  @override
  ConsumerState<ImportScheduleScreen> createState() => _ImportScheduleScreenState();
}

class _ImportScheduleScreenState extends ConsumerState<ImportScheduleScreen> {
  final _fileImportService = FileImportService();
  String? _selectedFarmId;
  List<Map<String, dynamic>> _parsedTasks = [];
  bool _isLoading = false;
  String _status = '';

  Future<void> _pickFile() async {
     setState(() => _status = 'Picking file...');
     FilePickerResult? result = await FilePicker.platform.pickFiles(
       type: FileType.custom,
       allowedExtensions: ['xlsx', 'xls', 'pdf'],
     );

     if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final ext = path.split('.').last.toLowerCase();
        
        setState(() {
          _isLoading = true;
          _status = 'Parsing $ext file...';
        });

        List<Map<String, dynamic>> tasks = [];
        try {
          if (ext == 'pdf') {
             tasks = await _fileImportService.parsePdf(path);
          } else {
             tasks = await _fileImportService.parseExcel(path);
          }
           setState(() {
             _parsedTasks = tasks;
             _status = 'Found ${tasks.length} tasks.';
           });
        } catch (e) {
           setState(() => _status = 'Error: $e');
        } finally {
           setState(() => _isLoading = false);
        }
     } else {
        setState(() => _status = '');
     }
  }

  Future<void> _saveTasks() async {
     if (_selectedFarmId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a farm')));
       return;
     }
     if (_parsedTasks.isEmpty) return;

     setState(() => _isLoading = true);
     
     try {
       final db = ref.read(databaseProvider);
       final notificationService = NotificationService();
       
       final batch = db.batch((batch) {
          int index = 0;
          for (final taskMap in _parsedTasks) {
             final id = const Uuid().v4();
             final date = taskMap['date'] as DateTime;
             final description = taskMap['description'] as String;
             
             final task = TasksCompanion(
                id: drift.Value(id),
                farmId: drift.Value(_selectedFarmId!),
                date: drift.Value(date),
                description: drift.Value(description),
                isCompleted: const drift.Value(false),
                isSynced: const drift.Value(false),
                updatedAt: drift.Value(DateTime.now()),
             );
             batch.insert(db.tasks, task);
             
             // Schedule Notification at 7:00 AM on task date
             // Note: ID must be int. We use hashcode or simple counter.
             // Ideally we store notification_id in DB to cancel later.
             // For simplicity, we just fire and forget here, using hashcode.
             int notifId = id.hashCode;
             
             // If date is in past, don't schedule.
             // If date is today but past 7 AM, maybe schedule for now + 1 min?
             // Simple rule: Schedule for 7 AM.
             
             final scheduledTime = DateTime(date.year, date.month, date.day, 7, 0);
             if (scheduledTime.isAfter(DateTime.now())) {
                notificationService.scheduleNotification(
                  id: notifId,
                  title: 'Farm Task Reminder',
                  body: description,
                  scheduledDate: scheduledTime,
                );
             }
             index++;
          }
       });
       
       await batch;
       
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${_parsedTasks.length} tasks!')));
         Navigator.of(context).pop();
       }
     } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save Error: $e')));
     } finally {
       if (mounted) setState(() => _isLoading = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.importSchedule ?? 'Import Schedule')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Farm Selection
            StreamBuilder<List<Farm>>(
              stream: db.select(db.farms).watch(),
              builder: (context, snapshot) {
                 final farms = snapshot.data ?? [];
                 if (farms.isEmpty) {
                   return const Text('No farms found. Add a farm first.');
                 }
                 return DropdownButtonFormField<String>(
                   value: _selectedFarmId,
                   decoration: InputDecoration(labelText: l10n?.selectFarm ?? 'Select Farm', border: const OutlineInputBorder()),
                   items: farms.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                   onChanged: (val) => setState(() => _selectedFarmId = val),
                 );
              },
            ),
            const SizedBox(height: 16),
            
            // File Picker
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(l10n?.pickFile ?? 'Pick Excel or PDF File'),
              onPressed: _isLoading ? null : _pickFile,
            ),
            const SizedBox(height: 8),
            Text(_status),
            const Divider(),
            
            // Preview
            Expanded(
              child: _parsedTasks.isEmpty 
               ? Center(child: Text(l10n?.parsing ?? 'Parsed tasks will appear here'))
               : ListView.builder(
                   itemCount: _parsedTasks.length,
                   itemBuilder: (context, index) {
                      final t = _parsedTasks[index];
                      return ListTile(
                        leading: const Icon(Icons.task),
                        title: Text(t['description']),
                        subtitle: Text(DateFormat.yMMMd().format(t['date'])),
                      );
                   },
                 ),
            ),
            
            if (_parsedTasks.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTasks,
                  child: Text(l10n?.save ?? 'Save to Schedule'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
