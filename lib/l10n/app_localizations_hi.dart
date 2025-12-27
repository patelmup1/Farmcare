// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'फसल सेवा';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get farms => 'खेत';

  @override
  String get schedule => 'अनुसूची';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get login => 'लॉग इन करें';

  @override
  String get signUp => 'साइन अप करें';

  @override
  String get welcome => 'वापसी पर स्वागत है, किसान!';

  @override
  String get addFarm => 'खेत जोड़ें';

  @override
  String get importSchedule => 'अनुसूची आयात करें';

  @override
  String get addTask => 'कार्य जोड़ें';

  @override
  String get manualTask => 'मैनुअल कार्य जोड़ें';

  @override
  String get selectFarm => 'खेत चुनें';

  @override
  String get date => 'दिनांक';

  @override
  String get description => 'विवरण';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get noTasks => 'कोई कार्य निर्धारित नहीं है।';

  @override
  String get taskAdded => 'कार्य सफलतापूर्वक जोड़ा गया!';

  @override
  String get pickFile => 'एक्सेल या पीडीएफ फाइल चुनें';

  @override
  String get parsing => 'पार्सिंग...';

  @override
  String foundTasks(Object count) {
    return '$count कार्य मिले';
  }

  @override
  String get localWeather => 'स्थानीय मौसम';

  @override
  String get rainChance => 'बारिश की संभावना';
}
