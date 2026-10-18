import 'dart:async';

import 'package:flutter/material.dart';

import 'util.dart';

const tabular = [FontFeature.tabularFigures()];

/// Colored circle with the first letter. Stands in for brand logos, which
/// are trademarks.
class ServiceAvatar extends StatelessWidget {
  const ServiceAvatar({super.key, required this.name, this.size = 40, this.muted = false});
  final String name;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
    final color = muted ? Theme.of(context).colorScheme.outline : avatarColor(trimmed);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        letter,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.44, height: 1),
      ),
    );
  }
}

/// Fades and lifts its child in once, after [delay].
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 18});
  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  late final _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, (1 - _a.value) * widget.offset), child: child),
      ),
    );
  }
}

/// Shows [child] with a size + fade transition, collapses to nothing when
/// [visible] is false. Adds [gap] below the child when visible.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.visible, required this.child, this.gap = 16});
  final bool visible;
  final Widget child;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SizeTransition(sizeFactor: a, alignment: Alignment.topCenter, child: child),
      ),
      child: visible
          ? KeyedSubtree(
              key: const ValueKey(true),
              child: Padding(padding: EdgeInsets.only(bottom: gap), child: child),
            )
          : const SizedBox(key: ValueKey(false), width: double.infinity),
    );
  }
}

/// Counts smoothly to [value] whenever it changes. Counts up from zero on
/// first build.
class Money extends StatelessWidget {
  const Money({super.key, required this.value, this.style, this.decimals = 2});
  final double value;
  final TextStyle? style;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        money(v, decimals: decimals),
        style: (style ?? const TextStyle()).copyWith(fontFeatures: tabular),
      ),
    );
  }
}

/// Shrinks slightly while pressed, so taps feel physical.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child});
  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A gentle, repeating pulse to draw the eye to time-sensitive things.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});
  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return ScaleTransition(
      scale: Tween(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// A white card on the tinted page background.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(text, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small grey label above a form field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

/// A tappable date "field" that opens the calendar.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.date, required this.onTap, this.placeholder = 'Pick a date'});
  final DateTime? date;
  final VoidCallback onTap;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final empty = date == null;
    return Material(
      color: empty ? cs.primaryContainer.withValues(alpha: 0.55) : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: empty ? cs.primary : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  empty ? placeholder : longDate(date!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: empty ? FontWeight.w600 : FontWeight.w500,
                    color: empty ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (!empty) Text(relDay(date!), style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> pickDate(BuildContext context, {DateTime? initial, String? help}) {
  final t = today();
  // Close the keyboard first (e.g. after typing the price); otherwise it
  // stays open and squeezes the calendar into the space above it.
  FocusManager.instance.primaryFocus?.unfocus();
  return showDatePicker(
    context: context,
    initialDate: initial ?? t,
    firstDate: DateTime(t.year - 2),
    lastDate: DateTime(t.year + 5, 12, 31),
    helpText: help,
  );
}

void showToast(BuildContext context, String message, {IconData icon = Icons.check_circle_rounded}) {
  final width = MediaQuery.sizeOf(context).width;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        width: width > 560 ? 480 : null,
        content: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.inversePrimary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
