# Subtrack

**A subscription tracker without a subscription.** See what you pay every month, get reminded before
payments and trial ends, and never miss a cancellation deadline – with no account, no cloud and no ads.

## Features

- **What you really pay** – monthly and yearly totals across all subscriptions, in your currency.
- **Quick add** – pick from 220+ known services and plans (streaming, software, gaming, news, ...) or add your own.
- **Reminders** – a notification a few days before each payment, before a free trial turns into a paid plan,
  and before the last day to cancel a contract with a notice period.
- **Cancel-by dates** – for contracts like "cancel 1 month before renewal", Subtrack works out the last safe day.
- **"Still using it?"** – every few months it asks whether you still use each subscription, so forgotten ones stand out.
- **Savings** – cancelled subscriptions move to their own list and show how much you save per year.
- **Import from your bank** – load a CSV export from your bank and Subtrack suggests the payments that repeat
  at a steady interval and amount. The file is read on your phone and never uploaded.
- **Export** – copy everything as CSV into Excel, Numbers or Google Sheets.
- **Local formats** – dates, numbers and the default currency follow your region; light and dark theme.

## Privacy

Everything is stored on your device. The release app does not even request the Internet permission,
so it cannot send your data anywhere. The only permission it asks for is to show reminders
(and to reschedule them after a restart).

## Building

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.13 or newer).

```bash
flutter pub get
flutter test
flutter run                 # on a connected Android device or emulator
flutter build apk --release
```

It also runs in the browser (`flutter run -d chrome`); there reminders are shown inside the app only.

## License

MIT – see [LICENSE](LICENSE).
