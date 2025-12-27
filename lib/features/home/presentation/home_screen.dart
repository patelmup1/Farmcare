import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../weather/presentation/weather_widget.dart';
import '../../farm/presentation/add_farm_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers.dart';
import '../../../core/database/database.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _logout() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final welcome = l10n?.welcome ?? 'Welcome to Farmer App';
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Farmer Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: l10n?.settings ?? 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Weather Section
            const WeatherWidget(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                welcome,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green[900], 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            
            // 2. Today's Tasks Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Tasks", 
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/schedule'),
                    child: const Text('View All'),
                  )
                ],
              ),
            ),
            
            SizedBox(
              height: 160, // Fixed height for horizontal list
              child: StreamBuilder<List<drift.TypedResult>>(
                stream: db.watchTodaysTasks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final results = snapshot.data ?? [];
                  
                  if (results.isEmpty) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50], // Light green bg
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[100]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            "No tasks today!",
                            style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Enjoy your day off.",
                            style: TextStyle(color: Colors.green[600], fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final row = results[index];
                      final task = row.readTable(db.tasks);
                      final farm = row.readTableOrNull(db.farms);
                      
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Card(
                          elevation: 2,
                          color: task.isCompleted ? Colors.green[50] : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: task.isCompleted ? BorderSide(color: Colors.green[200]!) : BorderSide.none,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.assignment, size: 16, color: Colors.orange),
                                    ),
                                    const Spacer(),
                                    if (task.isCompleted) 
                                      const Icon(Icons.check_circle, color: Colors.green, size: 18)
                                    else
                                      const Icon(Icons.circle_outlined, color: Colors.grey, size: 18)
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  task.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  farm?.name ?? 'Unknown Farm',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 3. Your Farms Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Your Farms", 
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pushNamed('/add-farm'),
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    tooltip: 'Add Farm',
                  )
                ],
              ),
            ),
            
            StreamBuilder<List<Farm>>(
              stream: db.select(db.farms).watch(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final farms = snapshot.data ?? [];
                
                if (farms.isEmpty) {
                   return const Center(child: Padding(
                     padding: EdgeInsets.all(32.0),
                     child: Text('No farms added yet.'),
                   ));
                }

                return ListView.builder(
                  shrinkWrap: true, // Vital for nested listview
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: farms.length,
                  padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                  itemBuilder: (context, index) {
                    final farm = farms[index];
                    final daysSincePlanting = DateTime.now().difference(farm.plantingDate).inDays;
                    final dayText = daysSincePlanting >= 0 ? 'Day ${daysSincePlanting + 1}' : 'Planned';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 0, // Flat styling
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!)
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            farm.cropType.isNotEmpty ? farm.cropType[0] : '?',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
                          ),
                        ),
                        title: Text(farm.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.eco, size: 14, color: Colors.green[400]),
                                  const SizedBox(width: 4),
                                  Text('${farm.cropType} • $dayText'),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('${farm.area} ${farm.areaUnit}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                         onTap: () {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => AddFarmScreen(farm: farm),
                             ),
                           );
                         },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/add-task');
        },
        label: const Text('New Task'),
        icon: const Icon(Icons.add_task),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
    );
  }
}
