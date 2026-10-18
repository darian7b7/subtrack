import 'package:flutter/material.dart';

import 'add_sheet.dart';
import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'util.dart';
import 'widgets.dart';

Future<void> showDetailSheet(BuildContext context, Subscription sub, {bool startCancel = false}) async {
  final msg = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DetailSheet(sub: sub, startCancel: startCancel),
  );
  if (msg != null && context.mounted) showToast(context, msg);
}

enum _Mode { view, cancel, delete }

class DetailSheet extends StatefulWidget {
  const DetailSheet({super.key, required this.sub, this.startCancel = false});
  final Subscription sub;
  final bool startCancel;

  @override
  State<DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<DetailSheet> {
  late _Mode _mode = widget.startCancel ? _Mode.cancel : _Mode.view;
  late DateTime _until = widget.sub.isTrial ? widget.sub.trialEnd! : widget.sub.nextPayment();

  Subscription get sub => widget.sub;

  @override
  Widget build(BuildContext context) {
    StoreScope.of(context); // rebuild on changes
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.paddingOf(context).bottom),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(a), child: child),
          ),
          child: switch (_mode) {
            _Mode.view => _view(context),
            _Mode.cancel => _cancel(context),
            _Mode.delete => _delete(context),
          },
        ),
      ),
    );
  }

  Widget _view(BuildContext context) {
    final store = StoreScope.read(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tones = Tones.of(context);
    final subtitle = [?sub.plan, sub.category].join(' · ');

    return Column(
      key: const ValueKey(_Mode.view),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ServiceAvatar(name: sub.name, size: 56, muted: sub.cancelled),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.name, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            StatusChip(sub: sub),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(money(sub.price), style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, fontFeatures: tabular)),
            const SizedBox(width: 8),
            Text(sub.cycleText.toLowerCase(), style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
        Text('${money(sub.yearly, decimals: 0)} a year', style: TextStyle(color: cs.onSurfaceVariant)),
        if (sub.isTrial) ...[
          const SizedBox(height: 16),
          _Note(
            icon: Icons.hourglass_bottom_rounded,
            color: tones.warn,
            bg: tones.warnBg,
            fg: tones.onWarnBg,
            text: 'Free trial ends ${weekdayDate(sub.trialEnd!)}. We remind you 2 days before.',
          ),
        ],
        if (sub.cancelled) ...[
          const SizedBox(height: 16),
          _Note(
            icon: Icons.savings_rounded,
            color: tones.good,
            bg: tones.goodBg,
            fg: tones.onGoodBg,
            text: daysUntil(sub.accessUntil!) >= 0
                ? 'Cancelled. Access until ${weekdayDate(sub.accessUntil!)}. You save ${money(sub.yearly, decimals: 0)} a year.'
                : 'Cancelled. ${money(sub.savedSoFar)} saved so far, ${money(sub.yearly, decimals: 0)} a year.',
          ),
        ],
        if (!sub.cancelled) ...[
          const SizedBox(height: 22),
          const FieldLabel('Next payments'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, d) in sub.nextPayments(4).indexed)
                FadeSlideIn(
                  delay: Duration(milliseconds: 60 * i),
                  offset: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: i == 0 ? cs.primaryContainer : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      i == 0 ? '${shortDate(d)} · ${relDay(d)}' : shortDate(d),
                      style: TextStyle(
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                        color: i == 0 ? cs.onPrimaryContainer : cs.onSurface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Rolled forward automatically from the date you picked.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 22),
          const FieldLabel('Remind me'),
          RemindPicker(
            value: sub.remindDays,
            onChanged: (v) {
              sub.remindDays = v;
              store.changed();
            },
          ),
          const SizedBox(height: 22),
          const FieldLabel('Cancellation notice'),
          NoticePicker(
            value: sub.notice,
            onChanged: (v) {
              sub.notice = v;
              store.changed();
            },
          ),
          if (sub.cancelDeadlines().firstOrNull case final d?) ...[
            const SizedBox(height: 12),
            _Note(
              icon: Icons.event_busy_rounded,
              color: cs.primary,
              bg: cs.primaryContainer.withValues(alpha: 0.5),
              fg: cs.onSurface,
              text: 'To stop the ${weekdayDate(d.renewal)} renewal, cancel by ${weekdayDate(d.cancelBy)} '
                  '(${relDay(d.cancelBy)}).',
            ),
          ],
        ],
        if (sub.card != null || sub.note != null) const SizedBox(height: 16),
        if (sub.card != null) _InfoRow(icon: Icons.credit_card_rounded, text: sub.card!),
        if (sub.note != null) _InfoRow(icon: Icons.sticky_note_2_outlined, text: sub.note!),
        const SizedBox(height: 24),
        if (!sub.cancelled)
          FilledButton.tonalIcon(
            onPressed: () => setState(() => _mode = _Mode.cancel),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('I cancelled'),
          )
        else
          FilledButton.tonalIcon(
            onPressed: () {
              store.reactivate(sub);
              Navigator.pop(context, '${sub.name} is back in your totals');
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reactivate'),
          ),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: cs.error),
          onPressed: () => setState(() => _mode = _Mode.delete),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  Widget _cancel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey(_Mode.cancel),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ServiceAvatar(name: sub.name, size: 44),
            const SizedBox(width: 12),
            Expanded(child: Text('You cancelled ${sub.name}', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          ],
        ),
        const SizedBox(height: 20),
        Text('Access until when?', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          'Most services keep working until the end of the paid period. It leaves your totals right away.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        DateField(
          date: _until,
          onTap: () async {
            final d = await pickDate(context, initial: _until, help: 'Access until');
            if (d != null) setState(() => _until = d);
          },
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            StoreScope.read(context).cancel(sub, _until);
            Navigator.pop(context, 'Cancelled ${sub.name}. You save ${money(sub.yearly, decimals: 0)} a year.');
          },
          child: const Text('Move to cancelled'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => widget.startCancel ? Navigator.pop(context) : setState(() => _mode = _Mode.view),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _delete(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey(_Mode.delete),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Delete ${sub.name}?', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          sub.cancelled
              ? 'It disappears from your cancelled list and savings.'
              : 'If you stopped paying for it, use “I cancelled” instead so you can see what you save.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
          onPressed: () {
            StoreScope.read(context).remove(sub);
            Navigator.pop(context, 'Deleted ${sub.name}');
          },
          child: const Text('Delete'),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => setState(() => _mode = _Mode.view), child: const Text('Keep it')),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.sub});
  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tones = Tones.of(context);
    final (label, fg, bg) = switch (sub) {
      _ when sub.cancelled => ('Cancelled', cs.onSurfaceVariant, cs.surfaceContainerHigh),
      _ when sub.isTrial => (
          sub.trialDaysLeft == 0 ? 'Trial ends today' : 'Trial · ${sub.trialDaysLeft}d left',
          tones.onWarnBg,
          tones.warnBg
        ),
      _ when sub.markedToCancel => ('To cancel', cs.onErrorContainer, cs.errorContainer),
      _ => ('Active', tones.onGoodBg, tones.goodBg),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.bg, required this.fg, required this.text});
  final IconData icon;
  final Color color, bg, fg;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
