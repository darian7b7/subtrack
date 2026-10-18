import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';
import 'store.dart';
import 'util.dart';

enum ReminderKind { payment, trial, deadline }

typedef PlannedReminder = ({DateTime at, String title, String body, ReminderKind kind});

/// Works out which notifications to show and when. No plugin calls, so it
/// can be tested without a device.
///
/// Reminders fire at [hour]:00 local time. Each subscription gets its next
/// payments up to about a year ahead; the plan is rebuilt whenever the app
/// opens or data changes, so dates keep rolling forward.
List<PlannedReminder> planReminders(Iterable<Subscription> subs, DateTime now, {int hour = 9, int max = 120}) {
  final start = dateOnly(now);
  final horizon = DateTime(start.year + 1, start.month, start.day);
  final out = <PlannedReminder>[];

  for (final s in subs) {
    if (s.cancelled) continue;
    final trialEnd = s.trialEnd == null ? null : dateOnly(s.trialEnd!);
    final inTrial = trialEnd != null && !trialEnd.isBefore(start);

    // The money-saving one: always 2 days before a trial turns paid.
    if (inTrial && !s.trialKept) {
      final at = DateTime(trialEnd.year, trialEnd.month, trialEnd.day - 2, hour);
      if (at.isAfter(now)) {
        out.add((
          at: at,
          title: 'Your ${s.name} trial becomes paid in 2 days',
          body: '${money(s.price)} ${s.cycleText.toLowerCase()} from ${weekdayDate(trialEnd)}. '
              'Cancel before then if you don’t want to pay.',
          kind: ReminderKind.trial,
        ));
      }
    }

    // Notice periods: 3 days before the last day to cancel, or that morning
    // if it was set up later than that.
    if (s.deadlineMatters) {
      for (final d in s.cancelDeadlines(start).take(2)) {
        var at = DateTime(d.cancelBy.year, d.cancelBy.month, d.cancelBy.day - 3, hour);
        if (!at.isAfter(now)) at = DateTime(d.cancelBy.year, d.cancelBy.month, d.cancelBy.day, hour);
        if (!at.isAfter(now)) continue;
        final lastDay = dateOnly(at) == dateOnly(d.cancelBy);
        out.add((
          at: at,
          title: lastDay ? 'Last day to cancel ${s.name}' : '${s.name}: 3 days left to cancel',
          body: 'Cancel by ${weekdayDate(d.cancelBy)} or it renews on ${weekdayDate(d.renewal)} '
              'for ${money(s.price)}.',
          kind: ReminderKind.deadline,
        ));
      }
    }

    if (s.remindDays == 0) continue;
    final when = s.remindDays == 1 ? 'tomorrow' : 'in ${s.remindDays} days';
    for (final d in s.paymentsBetween(start, horizon).take(13)) {
      if (inTrial && !s.trialKept && d == trialEnd) continue; // covered by the trial alert
      final at = DateTime(d.year, d.month, d.day - s.remindDays, hour);
      if (!at.isAfter(now)) continue;
      out.add((
        at: at,
        title: '${s.name} ${money(s.price)} $when',
        body: [weekdayDate(d), ?s.card].join(' · '),
        kind: ReminderKind.payment,
      ));
    }
  }

  out.sort((a, b) => a.at.compareTo(b.at));
  return out.take(max).toList();
}

/// Schedules [planReminders] as Android notifications. Does nothing on the
/// web, where the app only shows reminders inside the app.
class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool _askedThisSession = false;
  static Timer? _debounce;
  static Future<void> _queue = Future.value();

  /// True when the user has turned notifications off for the app.
  static final blocked = ValueNotifier(false);

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static Future<void> init(Store store) async {
    if (!supported) return;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      // Times are converted from the phone's clock either way; the zone only
      // matters around daylight saving changes.
      debugPrint('Time zone lookup failed: $e');
    }
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_notify')),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
      return;
    }
    store.addListener(() => _scheduleSoon(store));
    AppLifecycleListener(onResume: _recheck);
    _scheduleSoon(store);
  }

  static void _scheduleSoon(Store store) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _queue = _queue.then((_) => _sync(store)).catchError((Object e) => debugPrint('Reminder sync failed: $e'));
    });
  }

  static Future<void> _sync(Store store) async {
    if (!_ready) return;
    final plan = planReminders(store.subs, DateTime.now());

    // Ask only once there is something to remind about, not on first launch.
    if (plan.isNotEmpty && !_askedThisSession) {
      _askedThisSession = true;
      await _android?.requestNotificationsPermission();
    }
    blocked.value = plan.isNotEmpty && (await _android?.areNotificationsEnabled()) == false;

    await _plugin.cancelAllPendingNotifications();
    for (final (i, r) in plan.indexed) {
      await _plugin.zonedSchedule(
        id: i,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        // Inexact is fine for a morning reminder and needs no special
        // "alarms" permission, which Google Play restricts.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: _details(r.kind),
      );
    }

    // Build with --dart-define=REMINDER_SELFTEST=true to see the next
    // reminder right away instead of waiting for 9:00.
    if (const bool.fromEnvironment('REMINDER_SELFTEST') && plan.isNotEmpty) {
      final r = plan.first;
      await _plugin.show(id: 9999, title: r.title, body: r.body, notificationDetails: _details(r.kind));
    }
  }

  static NotificationDetails _details(ReminderKind kind) => NotificationDetails(
        android: switch (kind) {
          ReminderKind.trial => const AndroidNotificationDetails(
              'trial_alerts',
              'Free trial alerts',
              channelDescription: 'Two days before a free trial turns into a paid subscription',
              importance: Importance.high,
              priority: Priority.high,
              color: Color(0xFFE8961E),
            ),
          ReminderKind.deadline => const AndroidNotificationDetails(
              'cancel_deadlines',
              'Cancel-by dates',
              channelDescription: 'Before the last day to cancel a contract with a notice period',
              importance: Importance.high,
              priority: Priority.high,
              color: Color(0xFF2F6B5A),
            ),
          ReminderKind.payment => const AndroidNotificationDetails(
              'payment_reminders',
              'Payment reminders',
              channelDescription: 'Before each payment, on the days you choose',
              color: Color(0xFF2F6B5A),
            ),
        },
      );

  /// Opens Android's notification settings for this app. The banner
  /// updates when the user comes back.
  static Future<void> openSettings() => _plugin.openAppNotificationSettings();

  static Future<void> _recheck() async {
    if (blocked.value) blocked.value = (await _android?.areNotificationsEnabled()) == false;
  }
}
