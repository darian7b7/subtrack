import 'dart:convert';

import 'package:flutter/material.dart';

import 'catalog.dart';
import 'models.dart';
import 'store.dart';
import 'util.dart';
import 'widgets.dart';

void showImportSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ImportSheet(),
  );
}

class Suggestion {
  Suggestion({required this.name, required this.amount, required this.cycle, required this.last, required this.category, required this.count});
  final String name;
  final double amount;
  final Cycle cycle;
  final DateTime last;
  final String category;
  final int count;

  DateTime get next {
    var d = paymentDate(last, cycle, 3, 1);
    for (var k = 2; d.isBefore(today()); k++) {
      d = paymentDate(last, cycle, 3, k);
    }
    return d;
  }
}

/// Reads ISO (2026-09-03), day-first (03.09.2026, 03/09/26) and, in the
/// US or when the numbers say so, month-first (09/03/2026) dates.
DateTime? _parseDate(String s, {required bool monthFirst}) {
  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(s);
  if (iso != null) return DateTime(int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!));
  final m = RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})$').firstMatch(s);
  if (m == null) return null;
  final a = int.parse(m[1]!), b = int.parse(m[2]!);
  var y = int.parse(m[3]!);
  if (y < 100) y += 2000;
  // A part above 12 can only be the day, whatever the local habit.
  final mf = a > 12 ? false : (b > 12 ? true : monthFirst);
  final (day, month) = mf ? (b, a) : (a, b);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(y, month, day);
}

/// Splits one CSV line, keeping quoted fields like "1,234.56" together.
List<String> _cells(String line, String sep) {
  final out = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      quoted = !quoted;
    } else if (ch == sep && !quoted) {
      out.add(cell.toString().trim());
      cell.clear();
    } else {
      cell.write(ch);
    }
  }
  out.add(cell.toString().trim());
  return out;
}

/// An amount cell: digits with an optional sign and currency, e.g. "-12,99 €",
/// "$15.00", "1,234.56 USD". Not a date or an account number with letters.
final _amountCell = RegExp(r'^[-+]?\s*[^\d\s,.\-]{0,4}\s*[-+]?[\d.,]+\s*[^\d\s,.]{0,4}$');

/// Groups bank transactions by payee and keeps the ones that repeat at a
/// steady interval with a steady amount. Runs entirely on the device.
List<Suggestion> detectRecurring(String text, {bool? monthFirst}) {
  monthFirst ??= Formats.monthFirst;
  final rows = <({DateTime date, String desc, double amount})>[];
  for (final line in const LineSplitter().convert(text)) {
    if (line.trim().isEmpty) continue;
    final sep = line.contains(';') ? ';' : (line.contains('\t') ? '\t' : ',');
    final cells = _cells(line, sep);
    DateTime? date;
    double? amount;
    var desc = '';
    for (final c in cells) {
      final asDate = date == null ? _parseDate(c, monthFirst: monthFirst) : null;
      if (asDate != null) {
        date = asDate;
      } else if (amount == null && _amountCell.hasMatch(c) && parseMoney(c) != null) {
        amount = parseMoney(c);
      } else if (c.length > desc.length) {
        desc = c;
      }
    }
    if (date == null || amount == null || desc.isEmpty) continue;
    rows.add((date: date, desc: desc, amount: amount));
  }

  // Most banks export spending as negative numbers. If so, skip income.
  final signed = rows.any((r) => r.amount < 0);
  rows.removeWhere((r) => signed && r.amount > 0);

  String key(String d) => d
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => !RegExp(r'\d').hasMatch(w))
      .join(' ')
      .replaceAll(RegExp(r'[^a-z+ ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final groups = <String, List<({DateTime date, String desc, double amount})>>{};
  for (final r in rows) {
    groups.putIfAbsent(key(r.desc), () => []).add(r);
  }

  final out = <Suggestion>[];
  groups.forEach((k, list) {
    if (list.length < 2 || k.isEmpty) return;
    list.sort((a, b) => a.date.compareTo(b.date));
    final amounts = [for (final r in list) r.amount.abs()];
    final last = list.last;
    final steady = amounts.every((a) => (a - amounts.last).abs() <= amounts.last * 0.1);
    if (!steady) return;
    var gap = 0.0;
    for (var i = 1; i < list.length; i++) {
      gap += list[i].date.difference(list[i - 1].date).inDays;
    }
    gap /= list.length - 1;
    final Cycle cycle;
    if (gap >= 5 && gap <= 9) {
      cycle = Cycle.weekly;
    } else if (gap >= 26 && gap <= 35) {
      cycle = Cycle.monthly;
    } else if (gap >= 350 && gap <= 380) {
      cycle = Cycle.yearly;
    } else {
      return;
    }
    final match = matchService(k);
    out.add(Suggestion(
      name: match?.name ?? k.split(' ').map(cap).join(' '),
      amount: amounts.last,
      cycle: cycle,
      last: last.date,
      category: match?.category ?? 'Other',
      count: list.length,
    ));
  });
  out.sort((a, b) => b.amount.compareTo(a.amount));
  return out;
}

class _ImportSheet extends StatefulWidget {
  const _ImportSheet();

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  final _text = TextEditingController();
  List<Suggestion>? _found;
  final _added = <String>{};

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _analyze() => setState(() => _found = detectRecurring(_text.text));

  void _add(Suggestion s) {
    final store = StoreScope.read(context);
    store.add(Subscription(
      id: store.newId(),
      name: s.name,
      price: s.amount,
      cycle: s.cycle,
      anchor: s.next,
      category: s.category,
    ));
    setState(() => _added.add(s.name));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final store = StoreScope.of(context);
    final found = _found;
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SizedBox(
        height: (mq.size.height * 0.88 - mq.viewInsets.bottom).clamp(320.0, mq.size.height),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: found == null
              ? ListView(
                  key: const ValueKey('input'),
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + mq.padding.bottom),
                  children: [
                    Text('Import bank file', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Download your transactions as a CSV file in your banking app, then paste them here. '
                      'The file is read on this device. No bank login, nothing uploaded.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _text,
                      minLines: 8,
                      maxLines: 12,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      decoration: const InputDecoration(hintText: 'Date;Description;Amount\n2026-09-03;NETFLIX.COM;-13,99\n…'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _text.text.trim().isEmpty ? null : _analyze,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Find subscriptions'),
                    ),
                  ],
                )
              : ListView(
                  key: const ValueKey('results'),
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + mq.padding.bottom),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => setState(() => _found = null),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            found.isEmpty ? 'No repeating payments found' : 'Found ${found.length} repeating payments',
                            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (found.isEmpty)
                      Text(
                        'We look for the same payee at a steady amount, every week, month or year. '
                        'Try a longer date range, at least 2 to 3 months.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    for (final (i, s) in found.indexed)
                      FadeSlideIn(
                        delay: Duration(milliseconds: 80 * i),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SuggestionCard(
                            s: s,
                            added: _added.contains(s.name),
                            tracked: !_added.contains(s.name) && store.isTracked(s.name),
                            onAdd: () => _add(s),
                          ),
                        ),
                      ),
                    if (found.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.s, required this.added, required this.tracked, required this.onAdd});
  final Suggestion s;
  final bool added;
  final bool tracked;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cycle = s.cycle.label.toLowerCase();
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ServiceAvatar(name: s.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Looks like a $cycle payment to '),
                  TextSpan(text: s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ', ${money(s.amount)}.'),
                ])),
                const SizedBox(height: 2),
                Text('Seen ${s.count} times, last on ${shortDate(s.last)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: added
                ? Icon(Icons.check_circle_rounded, key: const ValueKey('added'), color: cs.primary, size: 32)
                : tracked
                    ? Text('Tracked', key: const ValueKey('tracked'), style: TextStyle(color: cs.onSurfaceVariant))
                    : FilledButton.tonal(
                        key: const ValueKey('add'),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                        onPressed: onAdd,
                        child: const Text('Add'),
                      ),
          ),
        ],
      ),
    );
  }
}
