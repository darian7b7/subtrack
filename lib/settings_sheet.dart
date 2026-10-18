import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'store.dart';
import 'util.dart';
import 'widgets.dart';

/// Common currencies, most used first. Names are in English like the app.
const currencies = <(String, String)>[
  ('USD', 'US dollar'),
  ('EUR', 'Euro'),
  ('GBP', 'British pound'),
  ('INR', 'Indian rupee'),
  ('JPY', 'Japanese yen'),
  ('CNY', 'Chinese yuan'),
  ('CAD', 'Canadian dollar'),
  ('AUD', 'Australian dollar'),
  ('BRL', 'Brazilian real'),
  ('MXN', 'Mexican peso'),
  ('CHF', 'Swiss franc'),
  ('SEK', 'Swedish krona'),
  ('NOK', 'Norwegian krone'),
  ('DKK', 'Danish krone'),
  ('PLN', 'Polish złoty'),
  ('CZK', 'Czech koruna'),
  ('HUF', 'Hungarian forint'),
  ('RON', 'Romanian leu'),
  ('TRY', 'Turkish lira'),
  ('UAH', 'Ukrainian hryvnia'),
  ('SAR', 'Saudi riyal'),
  ('AED', 'UAE dirham'),
  ('QAR', 'Qatari riyal'),
  ('KWD', 'Kuwaiti dinar'),
  ('EGP', 'Egyptian pound'),
  ('MAD', 'Moroccan dirham'),
  ('NGN', 'Nigerian naira'),
  ('KES', 'Kenyan shilling'),
  ('ZAR', 'South African rand'),
  ('ILS', 'Israeli shekel'),
  ('PKR', 'Pakistani rupee'),
  ('BDT', 'Bangladeshi taka'),
  ('IDR', 'Indonesian rupiah'),
  ('MYR', 'Malaysian ringgit'),
  ('SGD', 'Singapore dollar'),
  ('THB', 'Thai baht'),
  ('VND', 'Vietnamese dong'),
  ('PHP', 'Philippine peso'),
  ('KRW', 'South Korean won'),
  ('HKD', 'Hong Kong dollar'),
  ('TWD', 'New Taiwan dollar'),
  ('NZD', 'New Zealand dollar'),
  ('ARS', 'Argentine peso'),
  ('CLP', 'Chilean peso'),
  ('COP', 'Colombian peso'),
  ('PEN', 'Peruvian sol'),
];

String currencySymbol(String code) {
  try {
    return NumberFormat.simpleCurrency(locale: Formats.locale, name: code).currencySymbol;
  } catch (_) {
    return code;
  }
}

String currencyName(String code) => currencies.firstWhere((c) => c.$1 == code, orElse: () => (code, code)).$2;

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final code = store.currency;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Settings', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Material(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text(
                  currencySymbol(code),
                  style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700),
                ),
              ),
              title: const Text('Currency'),
              subtitle: Text('${currencyName(code)} ($code) · ${money(1234.5)}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const _CurrencyPicker(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Changing the currency doesn’t convert your amounts. Pick the one you pay in.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CurrencyPicker extends StatefulWidget {
  const _CurrencyPicker();

  @override
  State<_CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<_CurrencyPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final list = [
      for (final c in currencies)
        if (q.isEmpty || c.$1.toLowerCase().contains(q) || c.$2.toLowerCase().contains(q)) c,
    ];
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search currency'),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 16 + MediaQuery.paddingOf(context).bottom),
                children: [
                  for (final (code, name) in list)
                    ListTile(
                      leading: SizedBox(
                        width: 40,
                        child: Text(
                          currencySymbol(code),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(code),
                      trailing: code == store.currency ? Icon(Icons.check_rounded, color: cs.primary) : null,
                      onTap: () {
                        store.setCurrency(code);
                        Navigator.pop(context);
                        showToast(context, 'Showing amounts in $name');
                      },
                    ),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No currency matches. Try its 3-letter code, like USD.'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
