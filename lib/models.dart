import 'util.dart';

enum Cycle {
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly'),
  custom('Custom');

  const Cycle(this.label);
  final String label;
}

/// The k-th payment date counted from [anchor]. Always computed from the
/// anchor so a 31st-of-month payment keeps landing on month ends.
DateTime paymentDate(DateTime anchor, Cycle cycle, int everyMonths, int k) => switch (cycle) {
      Cycle.weekly => DateTime(anchor.year, anchor.month, anchor.day + 7 * k),
      Cycle.monthly => addMonths(anchor, k),
      Cycle.yearly => addMonths(anchor, 12 * k),
      Cycle.custom => addMonths(anchor, everyMonths * k),
    };

enum NoticeUnit { days, weeks, months }

/// How long before a renewal a contract must be cancelled, e.g. 1 month.
typedef Notice = ({int amount, NoticeUnit unit});

const noNotice = (amount: 0, unit: NoticeUnit.days);

String noticeLabel(Notice n) {
  if (n.amount == 0) return 'None';
  final unit = switch (n.unit) { NoticeUnit.days => 'day', NoticeUnit.weeks => 'week', NoticeUnit.months => 'month' };
  return '${n.amount} $unit${n.amount == 1 ? '' : 's'}';
}

/// The last day to cancel so that [renewal] is not charged.
DateTime cancelByFor(DateTime renewal, Notice n) => switch (n.unit) {
      NoticeUnit.days => DateTime(renewal.year, renewal.month, renewal.day - n.amount),
      NoticeUnit.weeks => DateTime(renewal.year, renewal.month, renewal.day - 7 * n.amount),
      NoticeUnit.months => addMonths(renewal, -n.amount),
    };

double monthlyCost(double price, Cycle cycle, int everyMonths) => switch (cycle) {
      Cycle.weekly => price * 52 / 12,
      Cycle.monthly => price,
      Cycle.yearly => price / 12,
      Cycle.custom => price / everyMonths,
    };

class Subscription {
  Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.cycle,
    required this.anchor,
    this.everyMonths = 3,
    this.category = 'Other',
    this.plan,
    this.card,
    this.note,
    this.trialEnd,
    this.remindDays = 1,
    this.notice = noNotice,
    DateTime? lastReviewed,
  }) : lastReviewed = lastReviewed ?? DateTime.now();

  final String id;
  String name;
  double price;
  Cycle cycle;
  int everyMonths;

  /// The payment date the user picked once. Every later date rolls from it.
  DateTime anchor;
  String category;
  String? plan;
  String? card;
  String? note;
  DateTime? trialEnd;
  bool trialKept = false;

  /// Days before a payment to remind. 0 = off.
  int remindDays;

  /// Cancellation notice period; amount 0 means it can be cancelled any time.
  Notice notice;
  bool cancelled = false;
  DateTime? accessUntil;
  bool markedToCancel = false;
  DateTime lastReviewed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'cycle': cycle.name,
        'everyMonths': everyMonths,
        'anchor': anchor.toIso8601String(),
        'category': category,
        'plan': plan,
        'card': card,
        'note': note,
        'trialEnd': trialEnd?.toIso8601String(),
        'trialKept': trialKept,
        'remindDays': remindDays,
        'noticeAmount': notice.amount,
        'noticeUnit': notice.unit.name,
        'cancelled': cancelled,
        'accessUntil': accessUntil?.toIso8601String(),
        'markedToCancel': markedToCancel,
        'lastReviewed': lastReviewed.toIso8601String(),
      };

  factory Subscription.fromJson(Map<String, dynamic> j) {
    DateTime? date(Object? v) => v == null ? null : DateTime.parse(v as String);
    return Subscription(
      id: j['id'] as String,
      name: j['name'] as String,
      price: (j['price'] as num).toDouble(),
      cycle: Cycle.values.byName(j['cycle'] as String),
      everyMonths: j['everyMonths'] as int? ?? 3,
      anchor: date(j['anchor'])!,
      category: j['category'] as String? ?? 'Other',
      plan: j['plan'] as String?,
      card: j['card'] as String?,
      note: j['note'] as String?,
      trialEnd: date(j['trialEnd']),
      remindDays: j['remindDays'] as int? ?? 1,
      notice: (
        amount: j['noticeAmount'] as int? ?? 0,
        unit: NoticeUnit.values.asNameMap()[j['noticeUnit']] ?? NoticeUnit.days,
      ),
      lastReviewed: date(j['lastReviewed']),
    )
      ..trialKept = j['trialKept'] as bool? ?? false
      ..cancelled = j['cancelled'] as bool? ?? false
      ..accessUntil = date(j['accessUntil'])
      ..markedToCancel = j['markedToCancel'] as bool? ?? false;
  }

  double get monthly => monthlyCost(price, cycle, everyMonths);
  double get yearly => monthly * 12;

  bool get isTrial => !cancelled && trialEnd != null && daysUntil(trialEnd!) >= 0;
  int get trialDaysLeft => trialEnd == null ? 0 : daysUntil(trialEnd!);

  String get cycleText => cycle == Cycle.custom ? 'Every $everyMonths months' : cycle.label;

  String get per => switch (cycle) {
        Cycle.weekly => '/wk',
        Cycle.monthly => '/mo',
        Cycle.yearly => '/yr',
        Cycle.custom => '/$everyMonths mo',
      };

  DateTime paymentAt(int k) => paymentDate(anchor, cycle, everyMonths, k);

  Iterable<DateTime> paymentsBetween(DateTime from, DateTime to) sync* {
    for (var k = 0; k < 10000; k++) {
      final d = paymentAt(k);
      if (d.isAfter(to)) return;
      if (!d.isBefore(from)) yield d;
    }
  }

  DateTime nextPayment() => paymentsBetween(today(), DateTime(9999)).first;

  List<DateTime> nextPayments(int n) => paymentsBetween(today(), DateTime(9999)).take(n).toList();

  bool get hasNotice => notice.amount > 0;

  /// Whether to warn about the cancellation deadline. Monthly plans would
  /// warn every month, so only long contracts and ones the user wants to
  /// cancel count.
  bool get deadlineMatters =>
      hasNotice && !cancelled && (markedToCancel || cycle == Cycle.yearly || cycle == Cycle.custom);

  /// Upcoming renewals that can still be avoided, with the last day to
  /// cancel for each.
  Iterable<({DateTime renewal, DateTime cancelBy})> cancelDeadlines([DateTime? from]) sync* {
    if (!hasNotice) return;
    final t = dateOnly(from ?? today());
    for (final renewal in paymentsBetween(t, DateTime(t.year + 3))) {
      final by = cancelByFor(renewal, notice);
      if (!by.isBefore(t)) yield (renewal: renewal, cancelBy: by);
    }
  }

  /// Money not spent since access ran out.
  double get savedSoFar {
    if (accessUntil == null) return 0;
    final days = -daysUntil(accessUntil!);
    if (days <= 0) return 0;
    return monthly * days / 30.44;
  }
}
