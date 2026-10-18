import 'dart:async';

import 'package:flutter/material.dart';

import 'catalog.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'util.dart';
import 'widgets.dart';

typedef AddResult = ({String name, int seconds});

Future<void> openAddSheet(BuildContext context) async {
  final r = await showModalBottomSheet<AddResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const AddSheet(),
  );
  if (r != null && context.mounted) {
    final fast = r.seconds <= 15;
    showToast(
      context,
      fast ? 'Added ${r.name} in ${r.seconds}s' : 'Added ${r.name}',
      icon: fast ? Icons.bolt_rounded : Icons.check_circle_rounded,
    );
  }
}

class AddSheet extends StatefulWidget {
  const AddSheet({super.key});

  @override
  State<AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<AddSheet> {
  final _clock = Stopwatch()..start();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _card = TextEditingController();
  final _note = TextEditingController();

  int _step = 0;
  Service? _service;
  Plan? _plan;
  Cycle _cycle = Cycle.monthly;
  int _every = 3;
  DateTime? _next;
  bool _more = false;
  DateTime? _trialEnd;
  String _category = 'Other';
  int _remind = 1;
  Notice _notice = noNotice;

  @override
  void initState() {
    super.initState();
    // Open the keyboard once the sheet has finished sliding up. Animating
    // both at once resizes the sheet on every frame and stutters.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final animation = ModalRoute.of(context)?.animation;
      if (animation == null || animation.isCompleted) {
        _searchFocus.requestFocus();
        return;
      }
      void onStatus(AnimationStatus status) {
        if (status != AnimationStatus.completed) return;
        animation.removeStatusListener(onStatus);
        if (mounted && _step == 0) _searchFocus.requestFocus();
      }

      animation.addStatusListener(onStatus);
    });
  }

  @override
  void dispose() {
    for (final c in [_search, _name, _price, _card, _note]) {
      c.dispose();
    }
    _searchFocus.dispose();
    super.dispose();
  }

  void _pick(Service s) => setState(() {
    _service = s;
    _name.text = s.name;
    _category = s.category;
    _setPlan(s.plans.first);
    _step = 1;
  });

  void _setPlan(Plan p) {
    _plan = p;
    final price = planPrice(p);
    if (price != null) _price.text = price.toStringAsFixed(2);
    _cycle = p.cycle;
    if (p.cycle == Cycle.custom) _every = 3;
  }

  void _custom(String name) => setState(() {
    _service = null;
    _plan = null;
    _name.text = cap(name.trim());
    _price.clear();
    _cycle = Cycle.monthly;
    _category = 'Other';
    _step = 1;
  });

  double? get _priceValue => parseMoney(_price.text);
  bool get _valid => _name.text.trim().isNotEmpty && (_priceValue ?? 0) > 0 && _next != null;

  Future<void> _pickNext() async {
    final d = await pickDate(context, initial: _next, help: 'Next payment date');
    if (d != null) setState(() => _next = d);
  }

  Future<void> _pickTrial() async {
    final t = today();
    final d = await pickDate(
      context,
      initial: _trialEnd ?? DateTime(t.year, t.month, t.day + 7),
      help: 'Free trial ends on',
    );
    if (d == null) return;
    setState(() {
      _trialEnd = d;
      // The first real charge is when the trial ends.
      if (_next == null || _next!.isBefore(d)) _next = d;
    });
  }

  void _save() {
    final store = StoreScope.read(context);
    String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final name = _name.text.trim();
    store.add(
      Subscription(
        id: store.newId(),
        name: name,
        price: _priceValue!,
        cycle: _cycle,
        everyMonths: _every,
        anchor: _next!,
        category: _category,
        plan: _plan?.name,
        card: opt(_card),
        note: opt(_note),
        trialEnd: _trialEnd,
        remindDays: _remind,
        notice: _notice,
      ),
    );
    Navigator.pop<AddResult>(context, (name: name, seconds: _clock.elapsed.inSeconds));
  }

  @override
  Widget build(BuildContext context) {
    // A fixed height that doesn't follow the keyboard; only the small
    // _KeyboardGap below rebuilds while the keyboard animates.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.9,
      child: _KeyboardGap(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, a) {
            final forward = child.key == const ValueKey(1);
            return FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: Offset(forward ? 0.12 : -0.12, 0), end: Offset.zero).animate(a),
                child: child,
              ),
            );
          },
          child: _step == 0 ? _buildSearch(context) : _buildDetails(context),
        ),
      ),
    );
  }

  // Step 1: type a few letters, tap the service.
  Widget _buildSearch(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final q = _search.text.trim();
    final results = searchCatalog(q);

    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add a subscription', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Type the first letters. We fill in the rest.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.go,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            onSubmitted: (v) {
              if (results.isNotEmpty) {
                _pick(results.first);
              } else if (v.trim().isNotEmpty) {
                _custom(v);
              }
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Netflix, Spotify, gym…',
              suffixIcon: q.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(_search.clear),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: q.isEmpty
                ? _popular(context)
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final (i, s) in results.indexed)
                        FadeSlideIn(
                          key: ValueKey(s.name),
                          delay: Duration(milliseconds: 25 * i),
                          offset: 8,
                          child: _ServiceTile(service: s, query: q, onTap: () => _pick(s)),
                        ),
                      FadeSlideIn(
                        key: const ValueKey('custom'),
                        offset: 8,
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.add_rounded, color: cs.onPrimaryContainer),
                          ),
                          title: Text('Add “${cap(q)}”'),
                          subtitle: Text(
                            results.isEmpty
                                ? 'Not on the list? Enter the price yourself.'
                                : 'Something else? Add it with your own price.',
                          ),
                          onTap: () => _custom(q),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _popular(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const FieldLabel('Popular'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // No per-chip fade-in: twelve fading chips cost a lot of GPU
            // time while the sheet itself is still sliding up.
            for (final s in popularServices)
              ActionChip(
                avatar: ServiceAvatar(name: s.name, size: 22),
                label: Text(s.name),
                onPressed: () => _pick(s),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Not on the list, like a local gym or a magazine? Type its name and add your own price.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  // Step 2: confirm price, cycle and date.
  Widget _buildDetails(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final s = _service;
    final later = _next == null ? <DateTime>[] : [for (var k = 1; k <= 3; k++) paymentDate(_next!, _cycle, _every, k)];

    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => setState(() => _step = 0),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              ServiceAvatar(name: _name.text, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: s != null
                    ? Text(s.name, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700))
                    : TextField(
                        controller: _name,
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(hintText: 'Name', isDense: true),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                if (s != null && s.plans.length > 1) ...[
                  const FieldLabel('Plan'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in s.plans)
                        ChoiceChip(
                          label: Text(planPrice(p) == null ? p.name : '${p.name} · ${money(planPrice(p)!)}'),
                          selected: p == _plan,
                          onSelected: (_) => setState(() => _setPlan(p)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                const FieldLabel('Price'),
                TextField(
                  controller: _price,
                  autofocus: s == null || !catalogPricesApply,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFeatures: tabular),
                  decoration: InputDecoration(
                    prefixText: '${Formats.symbol} ',
                    hintText: '0.00',
                    suffixIcon: s != null ? const Icon(Icons.edit_outlined, size: 18) : null,
                    helperText: s == null
                        ? null
                        : _plan != null && planPrice(_plan!) != null
                        ? 'Typical price. Check your bill, prices vary by country.'
                        : 'Enter the price from your bill.',
                  ),
                ),
                const SizedBox(height: 20),
                const FieldLabel('Billed'),
                SegmentedButton<Cycle>(
                  showSelectedIcon: false,
                  segments: [for (final c in Cycle.values) ButtonSegment(value: c, label: Text(c.label))],
                  selected: {_cycle},
                  onSelectionChanged: (v) => setState(() => _cycle = v.first),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: _cycle != Cycle.custom
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Text('Every'),
                              const SizedBox(width: 12),
                              IconButton.filledTonal(
                                tooltip: 'Fewer months',
                                onPressed: _every > 2 ? () => setState(() => _every--) : null,
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  '$_every',
                                  textAlign: TextAlign.center,
                                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'More months',
                                onPressed: _every < 24 ? () => setState(() => _every++) : null,
                                icon: const Icon(Icons.add_rounded),
                              ),
                              const SizedBox(width: 12),
                              const Text('months'),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                const FieldLabel('Next payment'),
                DateField(date: _next, onTap: _pickNext, placeholder: 'Pick the date once'),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: later.isEmpty
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 8, left: 2),
                          child: Row(
                            children: [
                              Icon(Icons.autorenew_rounded, size: 16, color: cs.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Then ${later.map(shortDate).join(', ')}… We work out the rest.',
                                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _more = !_more),
                    icon: AnimatedRotation(
                      turns: _more ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                    label: Text(_more ? 'Fewer options' : 'More: free trial, notice period, card, note'),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _more ? _moreFields(context) : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8, bottom: 16 + MediaQuery.paddingOf(context).bottom),
            child: FilledButton(
              onPressed: _valid ? _save : null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _next == null ? 'Pick the next payment date' : 'Add subscription',
                  key: ValueKey(_next == null),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moreFields(BuildContext context) {
    final tones = Tones.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: tones.warnBg,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              value: _trialEnd != null,
              onChanged: (v) => v ? _pickTrial() : setState(() => _trialEnd = null),
              secondary: Icon(Icons.hourglass_bottom_rounded, color: tones.warn),
              title: Text(
                'Free trial',
                style: TextStyle(color: tones.onWarnBg, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _trialEnd == null
                    ? 'We remind you 2 days before it becomes paid.'
                    : 'Ends ${weekdayDate(_trialEnd!)}. Reminder 2 days before.',
                style: TextStyle(color: tones.onWarnBg.withValues(alpha: 0.8)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const FieldLabel('Remind me before each payment'),
          RemindPicker(value: _remind, onChanged: (v) => setState(() => _remind = v)),
          const SizedBox(height: 20),
          const FieldLabel('Cancellation notice'),
          NoticePicker(value: _notice, onChanged: (v) => setState(() => _notice = v)),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: _notice.amount == 0 || _next == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 8, left: 2),
                    child: Text(
                      'To stop the ${shortDate(_next!)} renewal, cancel by ${shortDate(cancelByFor(_next!, _notice))}.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          const FieldLabel('Category'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in categories)
                ChoiceChip(
                  label: Text(c),
                  selected: c == _category,
                  avatar: CircleAvatar(backgroundColor: categoryColor(c), radius: 5),
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _card,
            decoration: const InputDecoration(
              labelText: 'Charged to',
              hintText: 'e.g. Visa ending 4421',
              prefixIcon: Icon(Icons.credit_card_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'e.g. shared with my brother',
              prefixIcon: Icon(Icons.sticky_note_2_outlined),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Draws the add sheet once, almost invisible, shortly after launch, so the
/// first real open doesn't stutter while Flutter prepares its text and
/// shapes for the GPU.
class AddSheetWarmup extends StatefulWidget {
  const AddSheetWarmup({super.key});

  @override
  State<AddSheetWarmup> createState() => _AddSheetWarmupState();
}

class _AddSheetWarmupState extends State<AddSheetWarmup> {
  bool _done = false;
  late final Timer _timer = Timer(const Duration(milliseconds: 1500), () => setState(() => _done = true));

  @override
  void initState() {
    super.initState();
    _timer; // start it
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: ExcludeFocus(
          child: Opacity(
            opacity: 0.01,
            child: SizedBox(
              width: 360,
              height: 640,
              child: Material(color: Theme.of(context).colorScheme.surface, child: const AddSheet()),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps the sheet's content above the keyboard.
class _KeyboardGap extends StatelessWidget {
  const _KeyboardGap({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: child,
  );
}

/// Common notice periods. Longer or unusual ones are rare enough that a
/// short list keeps adding fast.
class NoticePicker extends StatelessWidget {
  const NoticePicker({super.key, required this.value, required this.onChanged});
  final Notice value;
  final ValueChanged<Notice> onChanged;

  static const options = <Notice>[
    noNotice,
    (amount: 14, unit: NoticeUnit.days),
    (amount: 1, unit: NoticeUnit.months),
    (amount: 2, unit: NoticeUnit.months),
    (amount: 3, unit: NoticeUnit.months),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final n in options)
          ChoiceChip(
            label: Text(n.amount == 0 ? 'Cancel anytime' : noticeLabel(n)),
            selected: n == value,
            onSelected: (_) => onChanged(n),
          ),
      ],
    );
  }
}

class RemindPicker extends StatelessWidget {
  const RemindPicker({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: 0, label: Text('Off'), icon: Icon(Icons.notifications_off_outlined)),
        ButtonSegment(value: 1, label: Text('1 day')),
        ButtonSegment(value: 3, label: Text('3 days')),
        ButtonSegment(value: 7, label: Text('7 days')),
      ],
      selected: {value},
      onSelectionChanged: (v) => onChanged(v.first),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.query, required this.onTap});
  final Service service;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = service.name;
    final starts = name.toLowerCase().startsWith(query.toLowerCase());
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: ServiceAvatar(name: name),
      title: starts
          ? Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: name.substring(0, query.length),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: name.substring(query.length)),
                ],
              ),
            )
          : Text(name),
      subtitle: Text(
        service.fromPrice == null
            ? service.category
            : '${service.category} · from ${money(service.fromPrice!)}',
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
