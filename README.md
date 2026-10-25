# Farmcare — Farmer Crop Care

A Flutter farm-management application with farm records, task scheduling, weather information, and support for English, Hindi, and Gujarati.

## Project features

- Login and signup through Supabase
- Farm records and scheduled tasks
- Schedule import from files
- Local notifications
- Local database storage and synchronization
- Weather information
- Language settings for English, Hindi, and Gujarati

These features are represented in the source; this README does not claim that every platform or integration has been tested.

## Technology

Flutter, Dart, Riverpod, Supabase, and a local database.

## Local setup

Install the Flutter SDK and platform tooling, then clone the project:

```bash
git clone https://github.com/patelmup1/Farmcare.git
cd Farmcare
flutter pub get
```

Before running, configure a Supabase project you control. The current connection values are in [lib/main.dart](lib/main.dart); replace them with your project's URL and public anon key. Review [supabase_schema.sql](supabase_schema.sql) and apply the schema in your own project. Review access policies before storing real data.

Start an emulator or connect a supported device:

```bash
flutter run
```

## Repository guide

- [lib/features](lib/features): authentication, farms, schedules, weather, and settings
- [lib/core](lib/core): providers, database, synchronization, and notifications
- [lib/l10n](lib/l10n): translations
- [pubspec.yaml](pubspec.yaml): dependencies and assets
- [test](test): Flutter tests

## Development checks

```bash
flutter analyze
flutter test
```

## Feedback

Use [GitHub Issues](https://github.com/patelmup1/Farmcare/issues) for bugs and suggestions. Include the device, operating system, and steps to reproduce.

## License

No LICENSE file is currently included in this repository. Licensing terms need to be specified by the maintainer.
