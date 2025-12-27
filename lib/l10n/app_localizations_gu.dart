// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appTitle => 'પાક સંભાળ';

  @override
  String get dashboard => 'ડેશબોર્ડ';

  @override
  String get farms => 'ખેતરો';

  @override
  String get schedule => 'શેડ્યૂલ';

  @override
  String get settings => 'સેટિંગ્સ';

  @override
  String get login => 'લૉગ ઇન';

  @override
  String get signUp => 'સાઇન અપ કરો';

  @override
  String get welcome => 'ફરી સ્વાગત છે, ખેડૂત!';

  @override
  String get addFarm => 'ખેતર ઉમેરો';

  @override
  String get importSchedule => 'શેડ્યૂલ આયાત કરો';

  @override
  String get addTask => 'કાર્ય ઉમેરો';

  @override
  String get manualTask => 'મેન્યુઅલ કાર્ય ઉમેરો';

  @override
  String get selectFarm => 'ખેતર પસંદ કરો';

  @override
  String get date => 'તારીખ';

  @override
  String get description => 'વર્ણન';

  @override
  String get save => 'સાચવો';

  @override
  String get cancel => 'રદ કરો';

  @override
  String get noTasks => 'કોઈ કાર્ય શેડ્યૂલ નથી.';

  @override
  String get taskAdded => 'કાર્ય સફળતાપૂર્વક ઉમેરાયું!';

  @override
  String get pickFile => 'Excel અથવા PDF ફાઇલ પસંદ કરો';

  @override
  String get parsing => 'પાર્સિંગ...';

  @override
  String foundTasks(Object count) {
    return '$count કાર્યો મળ્યા';
  }

  @override
  String get localWeather => 'સ્થાનિક હવામાન';

  @override
  String get rainChance => 'વરસાદની શક્યતા';
}
