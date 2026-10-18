import 'package:flutter/material.dart';

import 'add_sheet.dart';
import 'detail_sheet.dart';
import 'import_sheet.dart';
import 'models.dart';
import 'reminders.dart';
import 'export.dart';
import 'settings_sheet.dart';
import 'store.dart';
import 'theme.dart';
import 'util.dart';
import 'widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final trials = store.trialsEnding;

    // Each section fades in once, one after another.
    var i = 0;
    Widget enter(Widget child) => FadeSlideIn(
      delay: Duration(milliseconds: 70 * i++),
      child: child,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Behind the content; covered and almost fully transparent.
          const Positioned(left: 0, top: 0, child: AddSheetWarmup()),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    enter(const _TopBar()),
                    const SizedBox(height: 12),
                    enter(const _TotalCard()),
                    const SizedBox(height: 16),
                    for (final s in store.active.where((s) => s.isTrial))
                      Reveal(
                        key: ValueKey('trial-${s.id}'),
                        visible: trials.contains(s),
                        child: enter(_TrialAlert(sub: s)),
                      ),
                    ValueListenableBuilder(
                      valueListenable: Reminders.blocked,
                      builder: (context, blocked, _) => Reveal(visible: blocked, child: const _NotificationsOff()),
                    ),
                    Reveal(visible: store.reminders.isNotEmpty, child: enter(const _Reminders())),
                    Reveal(visible: store.cancelDeadlines().isNotEmpty, child: enter(const _Deadlines())),
                    Reveal(visible: store.needsReview.isNotEmpty, child: enter(const _ReviewCard())),
                    if (store.subs.isEmpty) ...[
                      enter(const _Welcome()),
                      const SizedBox(height: 16),
                    ] else ...[
                      enter(const _Upcoming()),
                      const SizedBox(height: 16),
                      Reveal(visible: store.byCategory.isNotEmpty, child: enter(const _Categories())),
                      enter(const _AllSubs()),
                      const SizedBox(height: 16),
                    ],
                    Reveal(visible: store.cancelledSubs.isNotEmpty, child: enter(const _Cancelled())),
                    enter(const _Footer()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add subscription'),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.asset('assets/app_icon.png', width: 32, height: 32),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Subtrack',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'More',
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (v) => switch (v) {
            'import' => showImportSheet(context),
            'export' => showExportDialog(context),
            _ => showSettingsSheet(context),
          },
          itemBuilder: (_) => [
            _menuItem('import', Icons.upload_file_rounded, 'Import bank file'),
            _menuItem('export', Icons.table_chart_outlined, 'Export to spreadsheet'),
            _menuItem('settings', Icons.settings_outlined, 'Settings'),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) => PopupMenuItem(
    value: value,
    child: Row(children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(label)]),
  );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final on = cs.onPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You pay', style: tt.titleMedium?.copyWith(color: on.withValues(alpha: 0.8))),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Money(
                  value: store.monthlyTotal,
                  style: tt.displayMedium?.copyWith(color: on, fontWeight: FontWeight.w800, letterSpacing: -1.5),
                ),
                const SizedBox(width: 8),
                Text('/ month', style: tt.titleMedium?.copyWith(color: on.withValues(alpha: 0.8))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: on.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('That’s ', style: TextStyle(color: on, fontSize: 16)),
                  Money(
                    value: store.monthlyTotal * 12,
                    decimals: 0,
                    style: TextStyle(color: on, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(' a year', style: TextStyle(color: on, fontSize: 16)),
                ],
              ),
            ),
          ),
          if (store.trialMonthly > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.hourglass_bottom_rounded, size: 16, color: on.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '+${money(store.trialMonthly)}/month once your free trials end',
                    style: TextStyle(color: on.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The money-saving moment: a trial about to turn into a charge.
class _TrialAlert extends StatelessWidget {
  const _TrialAlert({required this.sub});
  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    final tones = Tones.of(context);
    final tt = Theme.of(context).textTheme;
    final days = sub.trialDaysLeft;
    final when = switch (days) {
      0 => 'today',
      1 => 'tomorrow',
      _ => 'in $days days',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tones.warnBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tones.warn.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pulse(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: tones.warn, shape: BoxShape.circle),
                  child: const Icon(Icons.hourglass_bottom_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FREE TRIAL ENDING',
                      style: tt.labelSmall?.copyWith(
                        color: tones.onWarnBg.withValues(alpha: 0.75),
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your ${sub.name} trial becomes paid $when.',
                      style: tt.titleMedium?.copyWith(color: tones.onWarnBg, fontWeight: FontWeight.w700, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${money(sub.price)} ${sub.cycleText.toLowerCase()} from ${weekdayDate(sub.trialEnd!)}. '
            'Cancel before then if you don’t want to pay.',
            style: TextStyle(color: tones.onWarnBg.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: tones.onWarnBg,
                  foregroundColor: tones.warnBg,
                  minimumSize: const Size(0, 44),
                ),
                onPressed: () => showDetailSheet(context, sub, startCancel: true),
                child: const Text('I cancelled'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: tones.onWarnBg, minimumSize: const Size(0, 44)),
                onPressed: () {
                  StoreScope.read(context).keepTrial(sub);
                  showToast(context, 'Keeping ${sub.name}. We’ll still remind you before each payment.');
                },
                child: const Text('I’ll keep it'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Reminders extends StatelessWidget {
  const _Reminders();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    return Panel(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Reminders',
                style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final r in store.reminders)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showDetailSheet(context, r.sub),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ServiceAvatar(name: r.sub.name, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: r.sub.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ' ${money(r.sub.price)} ${relDay(r.date)}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationsOff extends StatelessWidget {
  const _NotificationsOff();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Panel(
      color: cs.errorContainer,
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      child: Row(
        children: [
          Icon(Icons.notifications_off_rounded, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications are off, so you won’t get payment or trial reminders.',
              style: TextStyle(color: cs.onErrorContainer),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: cs.onErrorContainer),
            onPressed: Reminders.openSettings,
            child: const Text('Turn on'),
          ),
        ],
      ),
    );
  }
}

/// Contracts that renew soon unless cancelled before their notice period.
class _Deadlines extends StatelessWidget {
  const _Deadlines();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final items = store.cancelDeadlines();
    return Panel(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('Cancel-by dates', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          for (final d in items)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showDetailSheet(context, d.sub),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ServiceAvatar(name: d.sub.name, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(children: [
                            TextSpan(text: d.sub.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: ': cancel by ${weekdayDate(d.cancelBy)}'),
                          ])),
                          Text(
                            'Otherwise it renews on ${shortDate(d.renewal)} for ${money(d.sub.price)}',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: d.sub.markedToCancel ? cs.errorContainer : cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        switch (daysUntil(d.cancelBy)) { 0 => 'Today', 1 => 'Tomorrow', final n => '$n days' },
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: d.sub.markedToCancel ? cs.onErrorContainer : cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final list = store.needsReview;
    if (list.isEmpty) return const SizedBox.shrink();
    final s = list.first;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Still using it?', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (list.length > 1) Text('${list.length} to check', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a),
                child: c,
              ),
            ),
            child: Column(
              key: ValueKey(s.id),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ServiceAvatar(name: s.name, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(
                            '${money(s.monthly)} a month, ${money(s.yearly, decimals: 0)} a year',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                        onPressed: () => store.keep(s),
                        child: const Text('Yes, keep it'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          store.markToCancel(s);
                          showToast(
                            context,
                            'Marked ${s.name} to cancel. Tap it once you have.',
                            icon: Icons.flag_rounded,
                          );
                        },
                        child: const Text('Mark to cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Upcoming extends StatelessWidget {
  const _Upcoming();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tones = Tones.of(context);
    final items = store.upcoming();
    final total = items.fold(0.0, (a, p) => a + p.sub.price);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            'Next 30 days',
            trailing: Money(
              value: total,
              style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant),
            ),
          ),
          if (items.isEmpty) Text('Nothing due in the next 30 days.', style: TextStyle(color: cs.onSurfaceVariant)),
          for (final p in items)
            FadeSlideIn(
              key: ValueKey('${p.sub.id}-${p.date}'),
              offset: 8,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => showDetailSheet(context, p.sub),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _DateBadge(date: p.date),
                      const SizedBox(width: 12),
                      ServiceAvatar(name: p.sub.name, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              p.sub.isTrial && p.date == p.sub.trialEnd
                                  ? 'First payment after trial'
                                  : cap(relDay(p.date)),
                              style: TextStyle(
                                fontSize: 12,
                                color: p.sub.isTrial ? tones.warn : cs.onSurfaceVariant,
                                fontWeight: p.sub.isTrial ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        money(p.sub.price),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: tabular),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});
  final DateTime date;

  static const _m = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final soon = daysUntil(date) <= 1;
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: soon ? cs.primaryContainer : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              height: 1.1,
              color: soon ? cs.onPrimaryContainer : cs.onSurface,
            ),
          ),
          Text(
            _m[date.month - 1],
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              color: soon ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final cats = store.byCategory;
    final total = cats.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('By category'),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 12,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: FractionallySizedBox(
                    widthFactor: v,
                    child: Row(
                      children: [
                        for (final e in cats.entries)
                          Expanded(
                            flex: (e.value * 100).round().clamp(1, 1 << 30),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 2),
                              color: categoryColor(e.key),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final e in cats.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: categoryColor(e.key), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.key)),
                  Text(
                    '${(e.value / total * 100).round()}%',
                    style: TextStyle(color: cs.onSurfaceVariant, fontFeatures: tabular),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 84,
                    child: Text(
                      '${money(e.value)}/mo',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: tabular),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AllSubs extends StatelessWidget {
  const _AllSubs();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final list = store.active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SectionLabel(
            'Your subscriptions',
            trailing: Text(
              '${list.length}',
              style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (list.isEmpty)
          Panel(
            child: Column(
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 36, color: cs.primary),
                const SizedBox(height: 8),
                const Text('Nothing here yet', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Tap “Add subscription”. It takes about 15 seconds.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        for (final s in list)
          FadeSlideIn(
            key: ValueKey(s.id),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SubRow(sub: s),
            ),
          ),
      ],
    );
  }
}

class _SubRow extends StatelessWidget {
  const _SubRow({required this.sub});
  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final next = sub.nextPayment();
    final detail = sub.isTrial
        ? 'Free until ${shortDate(sub.trialEnd!)}'
        : '${sub.cycleText} · next ${shortDate(next)}';

    return Pressable(
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showDetailSheet(context, sub),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ServiceAvatar(name: sub.name, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              sub.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ),
                          if (sub.isTrial || sub.markedToCancel) ...[const SizedBox(width: 8), StatusChip(sub: sub)],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(detail, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      money(sub.price),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFeatures: tabular),
                    ),
                    Text(sub.per, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cancelled extends StatefulWidget {
  const _Cancelled();

  @override
  State<_Cancelled> createState() => _CancelledState();
}

class _CancelledState extends State<_Cancelled> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tones = Tones.of(context);
    final list = store.cancelledSubs;

    return Panel(
      padding: EdgeInsets.zero,
      color: tones.goodBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.savings_rounded, color: tones.good),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancelled (${list.length})',
                          style: TextStyle(fontWeight: FontWeight.w700, color: tones.onGoodBg),
                        ),
                        Row(
                          children: [
                            Text('You save ', style: TextStyle(color: tones.onGoodBg)),
                            Money(
                              value: store.savedPerYear,
                              decimals: 0,
                              style: TextStyle(color: tones.onGoodBg, fontWeight: FontWeight.w800),
                            ),
                            Text(' a year', style: TextStyle(color: tones.onGoodBg)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.expand_more_rounded, color: tones.onGoodBg),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: Column(
                      children: [
                        for (final s in list)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => showDetailSheet(context, s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  ServiceAvatar(name: s.name, size: 34, muted: true),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: TextStyle(fontWeight: FontWeight.w600, color: tones.onGoodBg),
                                        ),
                                        Text(
                                          daysUntil(s.accessUntil!) >= 0
                                              ? 'Access until ${shortDate(s.accessUntil!)}'
                                              : '${money(s.savedSoFar)} saved so far',
                                          style: TextStyle(fontSize: 12, color: tones.onGoodBg.withValues(alpha: 0.75)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${money(s.yearly, decimals: 0)}/yr',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: tones.good,
                                      fontFeatures: tabular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (list.isEmpty) Text('Nothing cancelled yet.', style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// First launch: nothing tracked yet.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Panel(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Pulse(
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.add_rounded, size: 30, color: cs.onPrimaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add your first subscription',
            textAlign: TextAlign.center,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Type a few letters, like “Net” for Netflix. It takes about 15 seconds. '
            'Then you see what you pay each month and each year.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => openAddSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add a subscription'),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => showImportSheet(context),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Or import from a bank file'),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final failed = StoreScope.of(context).storageFailed;
    final color = failed ? cs.error : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(failed ? Icons.warning_amber_rounded : Icons.lock_outline_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              failed
                  ? 'Couldn’t open storage on this device. Changes won’t be saved.'
                  : 'Private and offline. Your data stays on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
