import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/database/database.dart';
import '../../../core/providers.dart';
import '../../../../core/services/notification_service.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  
  String? _selectedFarmId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFarmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a farm')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final notificationService = NotificationService();
      
      final id = const Uuid().v4();
      final task = TasksCompanion(
        id: drift.Value(id),
        farmId: drift.Value(_selectedFarmId!),
        date: drift.Value(_selectedDate),
        description: drift.Value(_descController.text.trim()),
        isCompleted: const drift.Value(false),
        isSynced: const drift.Value(false),
        updatedAt: drift.Value(DateTime.now()),
      );

      await db.into(db.tasks).insert(task);

      // Schedule Notification
      final scheduledTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 7, 0);
      if (scheduledTime.isAfter(DateTime.now())) {
         await notificationService.scheduleNotification(
            id: id.hashCode,
            title: 'Farm Task Reminder',
            body: _descController.text.trim(),
            scheduledDate: scheduledTime,
         );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task added successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.manualTask ?? 'Add Manual Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Farm Dropdown
              StreamBuilder<List<Farm>>(
                stream: db.select(db.farms).watch(),
                builder: (context, snapshot) {
                  final farms = snapshot.data ?? [];
                  if (farms.isEmpty) {
                    return const Text('No farms found. Please add a farm first.');
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedFarmId,
                     decoration: InputDecoration(labelText: l10n?.selectFarm ?? 'Select Farm', border: const OutlineInputBorder()),
                    items: farms.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                    onChanged: (val) => setState(() => _selectedFarmId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${l10n?.date ?? "Date"}: ${DateFormat.yMMMd().format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: l10n?.description ?? 'Description', border: const OutlineInputBorder()),
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveTask,
                      child: Text(l10n?.save ?? 'Save Task'),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
