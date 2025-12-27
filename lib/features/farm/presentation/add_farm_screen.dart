import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';

class AddFarmScreen extends ConsumerStatefulWidget {
  final Farm? farm;
  const AddFarmScreen({super.key, this.farm});

  @override
  ConsumerState<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends ConsumerState<AddFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  
  String _cropType = 'Wheat';
  String _areaUnit = 'Acres';
  DateTime _plantingDate = DateTime.now();

  final List<String> _cropTypes = ['Wheat', 'Rice', 'Corn', 'Cotton', 'Sugarcane', 'Potato', 'Tomato'];
  final List<String> _areaUnits = ['Acres', 'Hectares', 'Bigha', 'Guntha'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.farm != null) {
      _nameController.text = widget.farm!.name;
      _areaController.text = widget.farm!.area.toString();
      _plantingDate = widget.farm!.plantingDate;
      
      // Ensure dropdown values exist in the list, otherwise fallback or add logic
      if (_cropTypes.contains(widget.farm!.cropType)) {
        _cropType = widget.farm!.cropType;
      }
      if (_areaUnits.contains(widget.farm!.areaUnit)) {
        _areaUnit = widget.farm!.areaUnit;
      }
    }
  }

  Future<void> _saveFarm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      // We don't strictly need supabase provider here for update if utilizing sync logic separately, 
      // but original code used it for userId. 
      // Ideally we get userId from authRepo or the existing farm.
      
      final authRepo = ref.read(authRepositoryProvider);
      final userId = authRepo.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      if (widget.farm != null) {
        // UPDATE Existing Farm
        final updatedFarm = widget.farm!.copyWith(
          name: _nameController.text.trim(),
          cropType: _cropType,
          plantingDate: _plantingDate,
          area: double.parse(_areaController.text.trim()),
          areaUnit: _areaUnit,
          isSynced: false, 
          updatedAt: drift.Value(DateTime.now()),
        );
        
        await db.update(db.farms).replace(updatedFarm);
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Farm updated successfully!')));
        }
      } else {
        // INSERT New Farm
        final farm = FarmsCompanion(
          id: drift.Value(const Uuid().v4()),
          userId: drift.Value(userId),
          name: drift.Value(_nameController.text.trim()),
          cropType: drift.Value(_cropType),
          plantingDate: drift.Value(_plantingDate),
          area: drift.Value(double.parse(_areaController.text.trim())),
          areaUnit: drift.Value(_areaUnit),
          isSynced: const drift.Value(false),
          updatedAt: drift.Value(DateTime.now()),
        );

        await db.into(db.farms).insert(farm);
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Farm saved successfully!')));
        }
      }

      if (mounted) {
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _plantingDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleKey = widget.farm != null ? 'Edit Farm' : (l10n?.addFarm ?? 'Add Farm');

    return Scaffold(
      appBar: AppBar(title: Text(titleKey)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Farm Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _cropType,
                decoration: const InputDecoration(labelText: 'Crop Type', border: OutlineInputBorder()),
                items: _cropTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _cropType = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _areaController,
                      decoration: const InputDecoration(labelText: 'Area', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                         if (val == null || val.isEmpty) return 'Enter area';
                         if (double.tryParse(val) == null) return 'Invalid number';
                         return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _areaUnit,
                      decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                      items: _areaUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => _areaUnit = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Planting Date: ${_plantingDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveFarm,
                      child: const Text('Save Farm'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
