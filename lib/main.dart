import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'home_screen.dart';
import 'reminders.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Build with --dart-define=FRAME_LOG=true to log slow frames to logcat.
  if (const bool.fromEnvironment('FRAME_LOG')) {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        final build = t.buildDuration.inMicroseconds / 1000;
        final raster = t.rasterDuration.inMicroseconds / 1000;
        if (build > 8 || raster > 8) {
          debugPrint('SLOW_FRAME build=${build.toStringAsFixed(1)}ms raster=${raster.toStringAsFixed(1)}ms');
        }
      }
    });
  }
  await initializeDateFormatting();
  final device = WidgetsBinding.instance.platformDispatcher.locale;
  final store = await Store.load(locale: device.toString());
  runApp(SubtrackApp(store: store, locale: englishFor(device)));
  // After the first frame, so a slow plugin never delays the app opening.
  unawaited(Reminders.init(store));
}

/// The app is in English; this picks the English variant closest to the
/// user's region, so the calendar starts on the right weekday and typed
/// dates use the local order (10/21/2026 in the US, 21/10/2026 elsewhere).
Locale englishFor(Locale device) {
  const variants = {'US', 'GB', 'AU', 'CA', 'IE', 'IN', 'NZ', 'SG', 'ZA'};
  final country = device.countryCode ?? '';
  if (variants.contains(country)) return Locale('en', country);
  return const Locale('en', 'GB');
}

class SubtrackApp extends StatelessWidget {
  const SubtrackApp({super.key, required this.store, this.locale = const Locale('en', 'GB')});
  final Store store;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      notifier: store,
      child: MaterialApp(
        title: 'Subtrack',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: [locale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const HomeScreen(),
      ),
    );
  }
}
