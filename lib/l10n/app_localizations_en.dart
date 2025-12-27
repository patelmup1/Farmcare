// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Crop Care';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get farms => 'Farms';

  @override
  String get schedule => 'Schedule';

  @override
  String get settings => 'Settings';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get welcome => 'Welcome back, Farmer!';

  @override
  String get addFarm => 'Add Farm';

  @override
  String get importSchedule => 'Import Schedule';

  @override
  String get addTask => 'Add Task';

  @override
  String get manualTask => 'Add Manual Task';

  @override
  String get selectFarm => 'Select Farm';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get noTasks => 'No tasks scheduled.';

  @override
  String get taskAdded => 'Task added successfully!';

  @override
  String get pickFile => 'Pick Excel or PDF File';

  @override
  String get parsing => 'Parsing...';

  @override
  String foundTasks(Object count) {
    return 'Found $count tasks';
  }

  @override
  String get localWeather => 'Local Weather';

  @override
  String get rainChance => 'Rain Chance';
}
