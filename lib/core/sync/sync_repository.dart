import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart';
import 'package:flutter/foundation.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

class SyncRepository {
  final AppDatabase db;
  final SupabaseClient supabase;

  SyncRepository(this.db, this.supabase);

  void initialize() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
       // On older connectivity_plus (v5), it returns a single result.
       bool isOnline = result == ConnectivityResult.mobile || 
                       result == ConnectivityResult.wifi ||
                       result == ConnectivityResult.ethernet;
                       
       if (isOnline) {
         debugPrint('Connectivity Restored: Triggering Sync...');
         syncAll();
       }
    });
  }

  /// Main sync function called when online
  Future<void> syncAll() async {
    // 1. Push Local Changes
    await _pushFarms();
    await _pushTasks();

    // 2. Pull Remote Changes
    await _pullFarms();
    await _pullTasks(); 
  }

  Future<void> _pushFarms() async {
    final unsynced = await (db.select(db.farms)..where((t) => t.isSynced.equals(false))).get();
    
    for (final row in unsynced) {
      try {
        final data = {
          'id': row.id,
          'user_id': supabase.auth.currentUser?.id,
          'name': row.name,
          'crop_type': row.cropType,
          'planting_date': row.plantingDate.toIso8601String(),
          'area': row.area,
          'area_unit': row.areaUnit,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await supabase.from('farms').upsert(data);
        
        // Mark as synced locally
        await (db.update(db.farms)..where((t) => t.id.equals(row.id)))
            .write(FarmsCompanion(isSynced: const Value(true)));
            
      } catch (e) {
        // Handle network error / conflict
        debugPrint('Error syncing farm ${row.id}: $e');
      }
    }
  }

  Future<void> _pushTasks() async {
    final unsynced = await (db.select(db.tasks)..where((t) => t.isSynced.equals(false))).get();
    
    for (final row in unsynced) {
      try {
        final data = {
          'id': row.id,
          'user_id': supabase.auth.currentUser?.id,
          'farm_id': row.farmId,
          'date': row.date.toIso8601String(),
          'description': row.description,
          'is_completed': row.isCompleted,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await supabase.from('tasks').upsert(data);
        
        await (db.update(db.tasks)..where((t) => t.id.equals(row.id)))
            .write(TasksCompanion(isSynced: const Value(true)));
            
      } catch (e) {
        debugPrint('Error syncing task ${row.id}: $e');
      }
    }
  }

  Future<void> _pullTasks() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase.from('tasks').select().eq('user_id', userId);
      
      final List<dynamic> data = response as List<dynamic>;
      for (final map in data) {
         final task = TasksCompanion(
           id: Value(map['id']),
           farmId: Value(map['farm_id']),
           date: Value(DateTime.parse(map['date'])),
           description: Value(map['description']),
           isCompleted: Value(map['is_completed'] ?? false),
           isSynced: const Value(true),
         );
         
         await db.into(db.tasks).insertOnConflictUpdate(task);
      }
    } catch (e) {
      debugPrint('Pull tasks error: $e');
    }
  }

  Future<void> _pullFarms() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get all farms (optimization: use last_sync_time)
      final response = await supabase.from('farms').select().eq('user_id', userId);
      
      final List<dynamic> data = response as List<dynamic>;
      for (final map in data) {
         // Upsert local
         final farm = FarmsCompanion(
           id: Value(map['id']),
           userId: Value(map['user_id']),
           name: Value(map['name']),
           cropType: Value(map['crop_type']),
           plantingDate: Value(DateTime.parse(map['planting_date'])),
           area: Value(map['area']),
           areaUnit: Value(map['area_unit']),
           isSynced: const Value(true), // coming from server, so it's synced
         );
         
         await db.into(db.farms).insertOnConflictUpdate(farm);
      }
    } catch (e) {
      debugPrint('Pull error: $e');
    }
  }
}
