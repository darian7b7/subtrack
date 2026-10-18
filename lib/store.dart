import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'util.dart';

typedef Payment = ({Subscription sub, DateTime date});

/// App state, saved on the device after every change. Nothing leaves it.
class Store extends ChangeNotifier {
  Store([this._prefs]);

  static const _key = 'subscriptions_v1';
  static const _currencyKey = 'currency';
  final SharedPreferences? _prefs;
  final List<Subscription> subs = [];

  /// True when device storage couldn't be opened. The app still works,
  /// but changes are lost when it closes.
  bool storageFailed = false;

  /// [locale] is the device's region, e.g. de_DE. It picks the number and
  /// date style, and the currency on first launch.
  static Future<Store> load({String locale = 'en_GB'}) async {
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Storage unavailable: $e');
      Formats.configure(locale: locale, currency: Formats.currencyFor(locale));
      return Store()..storageFailed = true;
    }
    final store = Store(prefs);
    var currency = prefs.getString(_currencyKey);
    if (currency == null) {
      // Remember the first guess so it doesn't change if the phone's region does.
      currency = Formats.currencyFor(locale);
      await prefs.setString(_currencyKey, currency);
    }
    Formats.configure(locale: locale, currency: currency);
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        store.subs.addAll([
          for (final e in jsonDecode(raw) as List) Subscription.fromJson(e as Map<String, dynamic>),
        ]);
      } catch (_) {
        // Keep unreadable data instead of overwriting it on the next save.
        await prefs.setString('${_key}_unreadable_${DateTime.now().millisecondsSinceEpoch}', raw);
      }
    }
    return store;
  }

  @override
  void notifyListeners() {
    _prefs?.setString(_key, jsonEncode([for (final s in subs) s.toJson()]));
    super.notifyListeners();
  }

  String get currency => Formats.currency;

  /// Amounts are not converted: this only changes how they are shown.
  void setCurrency(String code) {
    Formats.configure(currency: code);
    _prefs?.setString(_currencyKey, code);
    notifyListeners();
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  List<Subscription> get active => subs.where((s) => !s.cancelled).toList();
  List<Subscription> get cancelledSubs => subs.where((s) => s.cancelled).toList();

  /// Trials are free until they end, so they don't count yet.
  double get monthlyTotal => active.where((s) => !s.isTrial).fold(0.0, (a, s) => a + s.monthly);
  double get trialMonthly => active.where((s) => s.isTrial).fold(0.0, (a, s) => a + s.monthly);
  double get savedPerYear => cancelledSubs.fold(0.0, (a, s) => a + s.yearly);

  List<Subscription> get trialsEnding =>
      active.where((s) => s.isTrial && !s.trialKept && s.trialDaysLeft <= 7).toList()
        ..sort((a, b) => a.trialEnd!.compareTo(b.trialEnd!));

  /// Payments inside each subscription's own reminder window.
  List<Payment> get reminders {
    final out = <Payment>[];
    for (final s in active) {
      if (s.isTrial || s.remindDays == 0) continue;
      final d = s.nextPayment();
      if (daysUntil(d) <= s.remindDays) out.add((sub: s, date: d));
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  List<Payment> upcoming([int days = 30]) {
    final from = today();
    final to = DateTime(from.year, from.month, from.day + days);
    final out = <Payment>[
      for (final s in active)
        for (final d in s.paymentsBetween(from, to)) (sub: s, date: d),
    ];
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  Map<String, double> get byCategory {
    final m = <String, double>{};
    for (final s in active.where((s) => !s.isTrial)) {
      m[s.category] = (m[s.category] ?? 0) + s.monthly;
    }
    final entries = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  /// "Still using it?" asks again every ~3 months.
  List<Subscription> get needsReview => active
      .where((s) => !s.isTrial && !s.markedToCancel && DateTime.now().difference(s.lastReviewed).inDays >= 90)
      .toList();

  /// Cancellation deadlines in the next [days] days, soonest first.
  List<({Subscription sub, DateTime renewal, DateTime cancelBy})> cancelDeadlines([int days = 30]) {
    final out = <({Subscription sub, DateTime renewal, DateTime cancelBy})>[];
    for (final s in active.where((s) => s.deadlineMatters)) {
      final next = s.cancelDeadlines().firstOrNull;
      if (next != null && daysUntil(next.cancelBy) <= days) {
        out.add((sub: s, renewal: next.renewal, cancelBy: next.cancelBy));
      }
    }
    out.sort((a, b) => a.cancelBy.compareTo(b.cancelBy));
    return out;
  }

  bool isTracked(String name) => active.any((s) => s.name.toLowerCase() == name.toLowerCase());

  void add(Subscription s) {
    subs.insert(0, s);
    notifyListeners();
  }

  /// Call after mutating a subscription's fields directly.
  void changed() => notifyListeners();

  void cancel(Subscription s, DateTime accessUntil) {
    s
      ..cancelled = true
      ..accessUntil = accessUntil
      ..markedToCancel = false;
    notifyListeners();
  }

  void reactivate(Subscription s) {
    s
      ..cancelled = false
      ..accessUntil = null
      ..lastReviewed = DateTime.now();
    notifyListeners();
  }

  void remove(Subscription s) {
    subs.remove(s);
    notifyListeners();
  }

  void keep(Subscription s) {
    s.lastReviewed = DateTime.now();
    notifyListeners();
  }

  void markToCancel(Subscription s) {
    s
      ..markedToCancel = true
      ..lastReviewed = DateTime.now();
    notifyListeners();
  }

  void keepTrial(Subscription s) {
    s.trialKept = true;
    notifyListeners();
  }
}

class StoreScope extends InheritedNotifier<Store> {
  const StoreScope({super.key, required Store super.notifier, required super.child});

  /// Reads the store and rebuilds when it changes.
  static Store of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// Reads the store without listening. Use in callbacks.
  static Store read(BuildContext context) => context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
