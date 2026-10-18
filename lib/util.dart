import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Number, currency and date formats for the user's region. The app's text
/// is English, so dates use the closest English style ("Oct 19" in the US,
/// "19 Oct" elsewhere), while numbers follow the region ("1.044,00 €" in
/// Germany, "$1,044.00" in the US).
class Formats {
  static String locale = 'en_GB';
  static String currency = 'EUR';
  static String _dateLocale = 'en_GB';
  static NumberFormat _money = NumberFormat.simpleCurrency(locale: 'en_GB', name: 'EUR');
  static NumberFormat _money0 = NumberFormat.simpleCurrency(locale: 'en_GB', name: 'EUR', decimalDigits: 0);

  /// True where dates are written month first (US), for reading bank files.
  static bool monthFirst = false;

  static void configure({String? locale, String? currency}) {
    if (locale != null) Formats.locale = _supported(locale);
    if (currency != null) Formats.currency = currency;
    _money = NumberFormat.simpleCurrency(locale: Formats.locale, name: Formats.currency);
    _money0 = NumberFormat.simpleCurrency(locale: Formats.locale, name: Formats.currency, decimalDigits: 0);
    final parts = Formats.locale.split('_');
    final country = parts.length > 1 ? parts[1] : '';
    monthFirst = country == 'US';
    final english = parts.first == 'en' && DateFormat.localeExists(Formats.locale);
    _dateLocale = english ? Formats.locale : (monthFirst ? 'en_US' : 'en_GB');
  }

  static String get symbol => _money.currencySymbol;

  /// The currency people in [locale] usually pay in, e.g. de_DE → EUR.
  /// Decided by the country, since a language alone (ar, es, en) spans
  /// many currencies.
  static String currencyFor(String locale) {
    final parts = locale.split(RegExp('[_-]'));
    final country = parts.length > 1 ? parts.last.toUpperCase() : '';
    final known = _countryCurrency[country];
    if (known != null) return known;
    try {
      return NumberFormat.simpleCurrency(locale: _supported(locale)).currencyName ?? 'USD';
    } catch (_) {
      return 'USD';
    }
  }

  static String _supported(String l) {
    if (NumberFormat.localeExists(l)) return l;
    final lang = l.split('_').first;
    return NumberFormat.localeExists(lang) ? lang : 'en';
  }
}

/// Formats an amount in the user's currency, e.g. €1,044.00, or €1,044 with
/// [decimals] = 0.
String money(double v, {int decimals = 2}) => (decimals == 0 ? Formats._money0 : Formats._money).format(v);

/// Reads an amount typed by a user or found in a bank file: "12,99",
/// "1.234,56", "1,234.56", "-12,99 €", "$15". Null if it isn't a number.
double? parseMoney(String s) {
  var t = s.replaceAll(RegExp(r'[^\d,.\-]'), '');
  if (!RegExp(r'\d').hasMatch(t)) return null;
  if (t.endsWith('-')) t = '-${t.substring(0, t.length - 1)}';
  final comma = t.lastIndexOf(','), dot = t.lastIndexOf('.');
  if (comma >= 0 && dot >= 0) {
    // Both present: the last one is the decimal separator.
    t = comma > dot ? t.replaceAll('.', '').replaceAll(',', '.') : t.replaceAll(',', '');
  } else if (comma >= 0) {
    // "12,99" is a decimal comma; "1,234" (exactly 3 digits after) is thousands.
    final after = t.length - comma - 1;
    t = (after == 3 && ','.allMatches(t).length == 1) || ','.allMatches(t).length > 1
        ? t.replaceAll(',', '')
        : t.replaceAll(',', '.');
  } else if ('.'.allMatches(t).length > 1) {
    t = t.replaceAll('.', '');
  }
  return double.tryParse(t);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime today() => dateOnly(DateTime.now());

/// Whole days from today until [d]. Negative when [d] is in the past.
int daysUntil(DateTime d) => (dateOnly(d).difference(today()).inHours / 24).round();

/// Adds [months] (may be negative) to [d], clamping the day to the end of
/// shorter months (31 Jan + 1 month = 28/29 Feb).
DateTime addMonths(DateTime d, int months) {
  final total = d.month - 1 + months;
  final y = d.year + (total / 12).floor();
  final m = total % 12 + 1;
  final last = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, min(d.day, last));
}

// Short dates add the year only when it isn't this year, so yearly
// payments read "Oct 21, 2027" instead of repeating "Oct 21".
String shortDate(DateTime d) =>
    (d.year == today().year ? DateFormat.MMMd(Formats._dateLocale) : DateFormat.yMMMd(Formats._dateLocale)).format(d);
String longDate(DateTime d) => DateFormat.yMMMEd(Formats._dateLocale).format(d);
String weekdayDate(DateTime d) =>
    (d.year == today().year ? DateFormat.MMMEd(Formats._dateLocale) : DateFormat.yMMMEd(Formats._dateLocale)).format(d);

/// "today", "tomorrow", "in 3 days", "on 12 Nov".
String relDay(DateTime d) {
  final n = daysUntil(d);
  if (n == 0) return 'today';
  if (n == 1) return 'tomorrow';
  if (n > 1 && n < 7) return 'in $n days';
  return 'on ${shortDate(d)}';
}

String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

const _avatarPalette = [
  Color(0xFFE4572E),
  Color(0xFF2E86AB),
  Color(0xFF3BA55C),
  Color(0xFF8E5CD9),
  Color(0xFFD9A21B),
  Color(0xFFD94A8C),
  Color(0xFF1F9E9E),
  Color(0xFF5B6CD9),
  Color(0xFFB8572E),
  Color(0xFF4F7A28),
];

/// A stable color per service name. We never show real brand logos.
Color avatarColor(String name) {
  var h = 0;
  for (final c in name.toLowerCase().codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _avatarPalette[h % _avatarPalette.length];
}

const categories = [
  'Streaming',
  'Music',
  'Software',
  'Cloud',
  'Gaming',
  'News',
  'Fitness',
  'Food',
  'Shopping',
  'Learning',
  'Phone & Internet',
  'Other',
];

const _categoryColors = {
  'Streaming': Color(0xFFE4572E),
  'Music': Color(0xFF3BA55C),
  'Software': Color(0xFF5B6CD9),
  'Cloud': Color(0xFF2E86AB),
  'Gaming': Color(0xFF8E5CD9),
  'News': Color(0xFF6B7280),
  'Fitness': Color(0xFFD9A21B),
  'Food': Color(0xFFD94A8C),
  'Shopping': Color(0xFFB8572E),
  'Learning': Color(0xFF1F9E9E),
  'Phone & Internet': Color(0xFF4F7A28),
  'Other': Color(0xFF8A8F98),
};

Color categoryColor(String c) => _categoryColors[c] ?? const Color(0xFF8A8F98);

const _euro = [
  'AT',
  'BE',
  'BG',
  'CY',
  'DE',
  'EE',
  'ES',
  'FI',
  'FR',
  'GR',
  'HR',
  'IE',
  'IT',
  'LT',
  'LU',
  'LV',
  'MT',
  'NL',
  'PT',
  'SI',
  'SK',
];

final _countryCurrency = <String, String>{
  for (final c in _euro) c: 'EUR',
  'US': 'USD',
  'GB': 'GBP',
  'IN': 'INR',
  'JP': 'JPY',
  'CN': 'CNY',
  'CA': 'CAD',
  'AU': 'AUD',
  'NZ': 'NZD',
  'BR': 'BRL',
  'MX': 'MXN',
  'AR': 'ARS',
  'CL': 'CLP',
  'CO': 'COP',
  'PE': 'PEN',
  'CH': 'CHF',
  'LI': 'CHF',
  'SE': 'SEK',
  'NO': 'NOK',
  'DK': 'DKK',
  'IS': 'ISK',
  'PL': 'PLN',
  'CZ': 'CZK',
  'HU': 'HUF',
  'RO': 'RON',
  'TR': 'TRY',
  'UA': 'UAH',
  'RU': 'RUB',
  'RS': 'RSD',
  'BA': 'BAM',
  'MK': 'MKD',
  'AL': 'ALL',
  'MD': 'MDL',
  'GE': 'GEL',
  'AM': 'AMD',
  'AZ': 'AZN',
  'KZ': 'KZT',
  'SA': 'SAR',
  'AE': 'AED',
  'QA': 'QAR',
  'KW': 'KWD',
  'BH': 'BHD',
  'OM': 'OMR',
  'JO': 'JOD',
  'LB': 'LBP',
  'IQ': 'IQD',
  'EG': 'EGP',
  'MA': 'MAD',
  'DZ': 'DZD',
  'TN': 'TND',
  'IL': 'ILS',
  'PK': 'PKR',
  'BD': 'BDT',
  'LK': 'LKR',
  'NP': 'NPR',
  'ID': 'IDR',
  'MY': 'MYR',
  'SG': 'SGD',
  'TH': 'THB',
  'VN': 'VND',
  'PH': 'PHP',
  'KR': 'KRW',
  'HK': 'HKD',
  'TW': 'TWD',
  'NG': 'NGN',
  'KE': 'KES',
  'GH': 'GHS',
  'ZA': 'ZAR',
  'ET': 'ETB',
  'TZ': 'TZS',
  'UG': 'UGX',
};
