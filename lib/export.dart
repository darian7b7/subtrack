import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'store.dart';
import 'widgets.dart';

void showExportDialog(BuildContext context) {
  final store = StoreScope.read(context);
  String esc(String? v) => '"${(v ?? '').replaceAll('"', '""')}"';
  final rows = [
    'name,plan,price,cycle,next_payment,category,status,card,note',
    for (final s in store.subs)
      [
        esc(s.name),
        esc(s.plan),
        s.price.toStringAsFixed(2),
        esc(s.cycleText),
        s.cancelled ? '' : s.nextPayment().toIso8601String().substring(0, 10),
        esc(s.category),
        s.cancelled ? 'cancelled' : (s.isTrial ? 'trial' : 'active'),
        esc(s.card),
        esc(s.note),
      ].join(','),
  ];
  final csv = rows.join('\n');
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Export to spreadsheet'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy this and paste it into Excel, Numbers or Google Sheets.'),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: csv));
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) showToast(context, 'Copied ${store.subs.length} rows');
          },
        ),
      ],
    ),
  );
}
