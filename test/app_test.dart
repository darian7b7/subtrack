import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subtrack/add_sheet.dart';
import 'package:subtrack/catalog.dart';
import 'package:subtrack/import_sheet.dart';
import 'package:subtrack/main.dart';
import 'package:subtrack/models.dart';
import 'package:subtrack/reminders.dart';
import 'package:subtrack/store.dart';
import 'package:subtrack/util.dart';

/// A bank statement with a few subscriptions hidden among groceries.
String sampleStatement() {
  final t = today();
  String d(int monthsBack, int day) => DateTime(t.year, t.month - monthsBack, day).toIso8601String().substring(0, 10);
  final lines = <String>['Date;Description;Amount'];
  for (var m = 3; m >= 1; m--) {
    lines
      ..add('${d(m, 3)};NETFLIX.COM 866-579-7172;-13,99')
      ..add('${d(m, 4)};REWE Markt GmbH ${4400 + m};-${(38 + m * 7.3).toStringAsFixed(2).replaceAll('.', ',')}')
      ..add('${d(m, 6)};Google *YouTube Premium;-12,99')
      ..add('${d(m, 9)};CLEVERFIT MUENCHEN MITGL ${m}2$m;-29,90')
      ..add('${d(m, 11)};Amazon Marketplace ${m}8812;-${(17 + m * 11.5).toStringAsFixed(2).replaceAll('.', ',')}')
      ..add('${d(m, 14)};SPOTIFY P2C${m}A7F;-16,99')
      ..add('${d(m, 18)};Shell Tankstelle;-${(55 + m * 4.1).toStringAsFixed(2).replaceAll('.', ',')}')
      ..add('${d(m, 21)};PAYPAL *CHATGPT SUBSCR;-23,00')
      ..add('${d(m, 27)};Salary ACME GmbH;2840,00');
  }
  return lines.join('\n');
}

void main() {
  setUpAll(initializeDateFormatting);
  // Each test starts in the UK style with euros unless it says otherwise.
  setUp(() => Formats.configure(locale: 'en_GB', currency: 'EUR'));

  test('monthly dates clamp to month end', () {
    final a = DateTime(2026, 1, 31);
    expect(paymentDate(a, Cycle.monthly, 3, 1), DateTime(2026, 2, 28));
    expect(paymentDate(a, Cycle.monthly, 3, 2), DateTime(2026, 3, 31));
    expect(paymentDate(a, Cycle.custom, 3, 1), DateTime(2026, 4, 30));
  });

  test('money formats thousands', () {
    expect(money(1044), '€1,044.00');
    expect(money(790.56, decimals: 0), '€791');
  });

  group('global formats', () {
    String plain(String s) => s.replaceAll('\u00A0', ' ');

    test('numbers and currency follow the region', () {
      Formats.configure(locale: 'de_DE', currency: 'EUR');
      expect(plain(money(1044)), '1.044,00 €');
      Formats.configure(locale: 'en_US', currency: 'USD');
      expect(money(1044), '\$1,044.00');
      Formats.configure(locale: 'en_IN', currency: 'INR');
      expect(money(1044), '₹1,044.00');
      Formats.configure(locale: 'ja_JP', currency: 'JPY');
      expect(plain(money(1044)), contains('1,044'));
      expect(money(1044), isNot(contains('.00')));
    });

    test('dates use the local English style', () {
      final d = DateTime(today().year, 10, 19);
      Formats.configure(locale: 'en_US');
      expect(weekdayDate(d), matches(r'^\w{3}, Oct 19$'));
      Formats.configure(locale: 'de_DE');
      expect(weekdayDate(d), matches(r'^\w{3} 19 Oct$'));
      // Other years are spelled out so yearly dates don't look the same.
      expect(shortDate(DateTime(today().year + 1, 10, 19)), '19 Oct ${today().year + 1}');
    });

    test('currency defaults to the region', () {
      expect(Formats.currencyFor('en_US'), 'USD');
      expect(Formats.currencyFor('de_DE'), 'EUR');
      expect(Formats.currencyFor('en_IN'), 'INR');
      expect(Formats.currencyFor('ar_SA'), 'SAR');
      expect(Formats.currencyFor('xx_YY'), isNotEmpty);
    });

    test('amounts typed in any style are read correctly', () {
      expect(parseMoney('12,99'), 12.99);
      expect(parseMoney('12.99'), 12.99);
      expect(parseMoney('1.234,56'), 1234.56);
      expect(parseMoney('1,234.56'), 1234.56);
      expect(parseMoney('-12,99 €'), -12.99);
      expect(parseMoney('\$15'), 15);
      expect(parseMoney('1,234'), 1234);
      expect(parseMoney('Netflix'), isNull);
    });

    test('built-in prices only show in euros', () {
      final netflix = catalog.firstWhere((s) => s.name == 'Netflix');
      expect(planPrice(netflix.plans.first), 13.99);
      Formats.configure(currency: 'USD');
      expect(planPrice(netflix.plans.first), isNull);
      expect(netflix.fromPrice, isNull);
    });

    test('bank file with US dates and dollars', () {
      final csv = [
        'Date,Description,Amount',
        '08/03/2026,NETFLIX.COM,"-15.49"',
        '09/03/2026,NETFLIX.COM,"-15.49"',
        '10/03/2026,NETFLIX.COM,"-15.49"',
        '09/15/2026,Rent,"-1,850.00"',
      ].join('\n');
      final found = detectRecurring(csv, monthFirst: true);
      expect(found.single.name, 'Netflix');
      expect(found.single.amount, 15.49);
      expect(found.single.cycle, Cycle.monthly);
      expect(found.single.last, DateTime(2026, 10, 3));
    });

    test('currency choice is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await Store.load(locale: 'en_US');
      expect(first.currency, 'USD');
      first.setCurrency('INR');
      final second = await Store.load(locale: 'en_US');
      expect(second.currency, 'INR');
    });
  });

  group('notice periods', () {
    test('cancel-by date counts back from the renewal', () {
      final renewal = DateTime(2027, 1, 31);
      expect(cancelByFor(renewal, (amount: 1, unit: NoticeUnit.months)), DateTime(2026, 12, 31));
      expect(cancelByFor(renewal, (amount: 3, unit: NoticeUnit.months)), DateTime(2026, 10, 31));
      expect(cancelByFor(renewal, (amount: 14, unit: NoticeUnit.days)), DateTime(2027, 1, 17));
      expect(cancelByFor(DateTime(2027, 3, 31), (amount: 1, unit: NoticeUnit.months)), DateTime(2027, 2, 28));
    });

    test('skips renewals whose deadline has passed', () {
      final gym = Subscription(
        id: 'g',
        name: 'Gym',
        price: 299,
        cycle: Cycle.yearly,
        anchor: DateTime(2027, 1, 1),
        notice: (amount: 3, unit: NoticeUnit.months),
      );
      // 1 Jan 2027 needed cancelling by 1 Oct 2026, which is gone.
      final next = gym.cancelDeadlines(DateTime(2026, 10, 18)).first;
      expect(next.renewal, DateTime(2028, 1, 1));
      expect(next.cancelBy, DateTime(2027, 10, 1));
      expect(gym.deadlineMatters, isTrue);
    });

    test('monthly plans only warn when marked to cancel', () {
      final phone = Subscription(
        id: 'p',
        name: 'Phone',
        price: 20,
        cycle: Cycle.monthly,
        anchor: DateTime(2026, 11, 1),
        notice: (amount: 1, unit: NoticeUnit.months),
      );
      expect(phone.deadlineMatters, isFalse);
      phone.markedToCancel = true;
      expect(phone.deadlineMatters, isTrue);
    });

    test('deadline reminder 3 days before, or that morning if later', () {
      final now = DateTime(2026, 10, 17, 14, 30);
      Subscription gym(DateTime renewal) => Subscription(
            id: 'g',
            name: 'Gym',
            price: 299,
            cycle: Cycle.yearly,
            anchor: renewal,
            remindDays: 0,
            notice: (amount: 1, unit: NoticeUnit.months),
          );
      var plan = planReminders([gym(DateTime(2026, 12, 1))], now);
      expect(plan.first.kind, ReminderKind.deadline);
      expect(plan.first.at, DateTime(2026, 10, 29, 9));
      expect(plan.first.title, 'Gym: 3 days left to cancel');
      expect(
        plan.first.body,
        'Cancel by ${weekdayDate(DateTime(2026, 11, 1))} or it renews on ${weekdayDate(DateTime(2026, 12, 1))} for €299.00.',
      );

      plan = planReminders([gym(DateTime(2026, 11, 19))], now);
      expect(plan.first.at, DateTime(2026, 10, 19, 9));
      expect(plan.first.title, 'Last day to cancel Gym');
    });
  });

  test('bank file finds the subscriptions, not groceries or salary', () {
    final names = detectRecurring(sampleStatement()).map((s) => s.name).toSet();
    expect(names, containsAll(['Netflix', 'Spotify', 'YouTube Premium', 'ChatGPT Plus']));
    expect(names.any((n) => n.toLowerCase().contains('rewe')), isFalse);
    expect(names.any((n) => n.toLowerCase().contains('salary')), isFalse);
    expect(names.length, 5); // + the gym
  });

  test('subscriptions survive a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await Store.load();
    first.add(Subscription(
      notice: (amount: 2, unit: NoticeUnit.weeks),
      id: first.newId(),
      name: 'Disney+',
      price: 9.99,
      cycle: Cycle.monthly,
      anchor: DateTime(2026, 11, 2),
      trialEnd: DateTime(2026, 11, 2),
      note: 'shared with my brother',
    ));
    first.cancel(first.subs.single, DateTime(2026, 12, 1));

    final second = await Store.load();
    final s = second.subs.single;
    expect(s.name, 'Disney+');
    expect(s.price, 9.99);
    expect(s.trialEnd, DateTime(2026, 11, 2));
    expect(s.note, 'shared with my brother');
    expect(s.cancelled, isTrue);
    expect(s.accessUntil, DateTime(2026, 12, 1));
    expect(s.notice, (amount: 2, unit: NoticeUnit.weeks));
  });

  group('reminder plan', () {
    final now = DateTime(2026, 10, 17, 14, 30); // Saturday afternoon

    Subscription sub({String name = 'Spotify', DateTime? anchor, int remind = 1, DateTime? trialEnd, String? card}) =>
        Subscription(
          id: name,
          name: name,
          price: 11.99,
          cycle: Cycle.monthly,
          anchor: anchor ?? DateTime(2026, 10, 19),
          remindDays: remind,
          trialEnd: trialEnd,
          card: card,
        );

    test('reminds at 9:00 the chosen days before, with the payment in the title', () {
      final plan = planReminders([sub(card: 'Visa ending 4421')], now);
      expect(plan.first.at, DateTime(2026, 10, 18, 9));
      expect(plan.first.title, 'Spotify €11.99 tomorrow');
      expect(plan.first.body, '${weekdayDate(DateTime(2026, 10, 19))} · Visa ending 4421');
      expect(plan[1].at, DateTime(2026, 11, 18, 9)); // rolls forward monthly
      expect(plan.length, 12); // about a year ahead
    });

    test('skips reminders whose time has already passed', () {
      // Payment tomorrow with a 3-day reminder: that was due on Thursday.
      final plan = planReminders([sub(remind: 3, anchor: DateTime(2026, 10, 18))], now);
      expect(plan.first.at, DateTime(2026, 11, 15, 9));
      expect(plan.first.title, 'Spotify €11.99 in 3 days');
    });

    test('free trial gets one alert 2 days before, not a duplicate payment reminder', () {
      final s = sub(name: 'Disney+', anchor: DateTime(2026, 10, 25), trialEnd: DateTime(2026, 10, 25));
      final plan = planReminders([s], now);
      expect(plan.first.kind, ReminderKind.trial);
      expect(plan.first.at, DateTime(2026, 10, 23, 9));
      expect(plan.first.title, 'Your Disney+ trial becomes paid in 2 days');
      expect(plan.where((r) => r.at == DateTime(2026, 10, 24, 9)), isEmpty);
    });

    test('nothing for cancelled subscriptions or reminders turned off', () {
      final cancelled = sub()..cancelled = true;
      expect(planReminders([cancelled, sub(name: 'Netflix', remind: 0)], now), isEmpty);
    });
  });

  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    testWidgets('first launch, then add flow at ${size.width}px', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // The welcome icon pulses forever; reduced motion stops it so the test can settle.
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      SharedPreferences.setMockInitialValues({});
      final store = await Store.load(locale: 'de_DE');
      await tester.pumpWidget(SubtrackApp(store: store));
      await tester.pumpAndSettle();
      // Let the hidden add-sheet warm-up finish and disappear.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(AddSheetWarmup), findsOneWidget);
      expect(find.byType(AddSheet), findsNothing);
      expect(find.text('Add your first subscription'), findsOneWidget);
      expect(store.subs, isEmpty);

      await tester.tap(find.text('Add a subscription'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Net');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Netflix').first);
      await tester.pumpAndSettle();
      expect(find.text('13.99'), findsOneWidget);

      await tester.tap(find.text('More: free trial, notice period, card, note'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick the date once'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add subscription'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Added Netflix'), findsOneWidget);
      expect(find.text('Add your first subscription'), findsNothing);
      expect((await Store.load()).subs.single.name, 'Netflix');
    });
  }
}
