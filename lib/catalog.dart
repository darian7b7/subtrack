import 'dart:math';

import 'models.dart';
import 'util.dart';

class Plan {
  const Plan(this.name, this.price, [this.cycle = Cycle.monthly]);
  final String name;

  /// Typical price in euros, or null where we don't have one.
  final double? price;
  final Cycle cycle;
}

class Service {
  const Service(this.name, this.category, this.plans);
  final String name;
  final String category;

  /// Most common plan first. Prices are typical EU prices and only a
  /// starting point: the user always confirms the amount.
  final List<Plan> plans;

  /// Cheapest known plan price in the user's currency, or null.
  double? get fromPrice {
    if (!catalogPricesApply) return null;
    final known = [for (final p in plans) ?p.price];
    return known.isEmpty ? null : known.reduce(min);
  }
}

/// The built-in prices are euro prices. In any other currency they would be
/// wrong, so the app then shows plans without prices and the user types it.
bool get catalogPricesApply => Formats.currency == 'EUR';

/// A plan's price in the user's currency, or null if we don't know it.
double? planPrice(Plan p) => catalogPricesApply ? p.price : null;

const _y = Cycle.yearly;

const catalog = <Service>[
  // Streaming
  Service('Netflix', 'Streaming', [Plan('Standard', 13.99), Plan('Standard with ads', 4.99), Plan('Premium', 19.99)]),
  Service('Disney+', 'Streaming', [Plan('Standard', 9.99), Plan('Standard with ads', 5.99), Plan('Premium', 13.99), Plan('Standard yearly', 99.90, _y)]),
  Service('Amazon Prime', 'Streaming', [Plan('Monthly', 8.99), Plan('Yearly', 89.90, _y)]),
  Service('Prime Video', 'Streaming', [Plan('Standalone', 8.99)]),
  Service('Apple TV+', 'Streaming', [Plan('Monthly', 9.99)]),
  Service('Max', 'Streaming', [Plan('Standard', 9.99), Plan('Basic with ads', 5.99), Plan('Premium', 13.99)]),
  Service('Paramount+', 'Streaming', [Plan('Standard', 7.99), Plan('Premium', 10.99)]),
  Service('Hulu', 'Streaming', [Plan('With ads', 9.99), Plan('No ads', 18.99)]),
  Service('Peacock', 'Streaming', [Plan('Premium', 7.99), Plan('Premium Plus', 13.99)]),
  Service('Crunchyroll', 'Streaming', [Plan('Fan', 6.99), Plan('Mega Fan', 9.99), Plan('Ultimate Fan', 14.99)]),
  Service('DAZN', 'Streaming', [Plan('Standard', 34.99), Plan('Unlimited', 44.99)]),
  Service('Sky', 'Streaming', [Plan('Entertainment', 15.00), Plan('Cinema', 25.00)]),
  Service('WOW', 'Streaming', [Plan('Films & Series', 9.98), Plan('Live Sport', 29.99)]),
  Service('Canal+', 'Streaming', [Plan('Essentiel', 24.99)]),
  Service('RTL+', 'Streaming', [Plan('Premium', 6.99), Plan('Max', 12.99)]),
  Service('Joyn PLUS+', 'Streaming', [Plan('Monthly', 6.99)]),
  Service('Mubi', 'Streaming', [Plan('Monthly', 12.99), Plan('Yearly', 95.88, _y)]),
  Service('Discovery+', 'Streaming', [Plan('Monthly', 4.99)]),
  Service('Viaplay', 'Streaming', [Plan('Standard', 11.99)]),
  Service('Britbox', 'Streaming', [Plan('Monthly', 6.99)]),
  Service('Curiosity Stream', 'Streaming', [Plan('Yearly', 19.99, _y)]),
  Service('Shudder', 'Streaming', [Plan('Monthly', 5.99)]),
  Service('Plex Pass', 'Streaming', [Plan('Monthly', 6.99), Plan('Yearly', 69.99, _y)]),
  Service('Twitch Turbo', 'Streaming', [Plan('Monthly', 11.99)]),
  Service('YouTube Premium', 'Streaming', [Plan('Individual', 12.99), Plan('Family', 25.99), Plan('Student', 7.99), Plan('Lite', 6.99)]),
  Service('Zattoo', 'Streaming', [Plan('Smart HD', 6.99), Plan('Ultimate', 13.99)]),
  Service('waipu.tv', 'Streaming', [Plan('Perfect Plus', 12.99)]),
  Service('Funimation', 'Streaming', [Plan('Premium', 5.99)]),
  Service('Nebula', 'Streaming', [Plan('Yearly', 30.00, _y)]),
  Service('F1 TV', 'Streaming', [Plan('Pro', 7.99), Plan('Pro yearly', 64.99, _y)]),

  // Music & audio
  Service('Spotify', 'Music', [Plan('Individual', 11.99), Plan('Duo', 16.99), Plan('Family', 19.99), Plan('Student', 6.49)]),
  Service('Apple Music', 'Music', [Plan('Individual', 10.99), Plan('Family', 16.99), Plan('Student', 5.99)]),
  Service('YouTube Music', 'Music', [Plan('Individual', 10.99), Plan('Family', 16.99)]),
  Service('Amazon Music Unlimited', 'Music', [Plan('Individual', 10.99), Plan('Prime members', 9.99)]),
  Service('Deezer', 'Music', [Plan('Premium', 11.99), Plan('Duo', 15.99), Plan('Family', 19.99)]),
  Service('Tidal', 'Music', [Plan('Individual', 10.99), Plan('Family', 16.99)]),
  Service('SoundCloud Go+', 'Music', [Plan('Monthly', 10.99)]),
  Service('Qobuz', 'Music', [Plan('Studio', 12.99)]),
  Service('Audible', 'Music', [Plan('Premium Plus', 9.95)]),
  Service('Storytel', 'Music', [Plan('Unlimited', 14.99)]),
  Service('BookBeat', 'Music', [Plan('Standard', 14.90)]),
  Service('Pocket Casts Plus', 'Music', [Plan('Yearly', 39.99, _y)]),
  Service('Calm', 'Music', [Plan('Yearly', 69.99, _y)]),
  Service('Headspace', 'Music', [Plan('Monthly', 12.99), Plan('Yearly', 69.99, _y)]),

  // Software
  Service('Microsoft 365', 'Software', [Plan('Personal', 99.00, _y), Plan('Family', 129.00, _y), Plan('Personal monthly', 10.00)]),
  Service('Adobe Creative Cloud', 'Software', [Plan('All Apps', 66.45), Plan('Photography', 11.99)]),
  Service('Adobe Acrobat', 'Software', [Plan('Pro', 23.99), Plan('Standard', 17.99)]),
  Service('Adobe Lightroom', 'Software', [Plan('1TB', 11.99)]),
  Service('Adobe Photoshop', 'Software', [Plan('Monthly', 26.21)]),
  Service('Canva Pro', 'Software', [Plan('Monthly', 11.99), Plan('Yearly', 110.00, _y)]),
  Service('Figma', 'Software', [Plan('Professional', 15.00)]),
  Service('Notion', 'Software', [Plan('Plus', 10.00), Plan('Plus yearly', 96.00, _y)]),
  Service('Evernote', 'Software', [Plan('Personal', 14.99)]),
  Service('Todoist', 'Software', [Plan('Pro yearly', 48.00, _y), Plan('Pro', 5.00)]),
  Service('1Password', 'Software', [Plan('Individual yearly', 35.88, _y), Plan('Families yearly', 59.88, _y)]),
  Service('Bitwarden', 'Software', [Plan('Premium', 10.00, _y)]),
  Service('Dashlane', 'Software', [Plan('Premium', 59.99, _y)]),
  Service('LastPass', 'Software', [Plan('Premium', 36.00, _y)]),
  Service('NordVPN', 'Software', [Plan('Basic yearly', 59.88, _y), Plan('Monthly', 12.99)]),
  Service('ExpressVPN', 'Software', [Plan('Monthly', 12.95), Plan('Yearly', 99.95, _y)]),
  Service('Surfshark', 'Software', [Plan('Yearly', 47.88, _y)]),
  Service('Proton', 'Software', [Plan('Mail Plus', 4.99), Plan('Unlimited', 12.99)]),
  Service('ChatGPT Plus', 'Software', [Plan('Plus', 23.00)]),
  Service('Claude Pro', 'Software', [Plan('Pro', 18.00), Plan('Max', 90.00)]),
  Service('Gemini Advanced', 'Software', [Plan('Google One AI Premium', 21.99)]),
  Service('GitHub Copilot', 'Software', [Plan('Pro', 10.00), Plan('Pro yearly', 100.00, _y)]),
  Service('GitHub', 'Software', [Plan('Pro', 4.00)]),
  Service('JetBrains', 'Software', [Plan('All Products', 28.90)]),
  Service('Grammarly', 'Software', [Plan('Premium', 12.00)]),
  Service('DeepL Pro', 'Software', [Plan('Starter', 8.74)]),
  Service('Duolingo Super', 'Learning', [Plan('Yearly', 83.99, _y), Plan('Monthly', 12.99)]),
  Service('Babbel', 'Learning', [Plan('3 months', 41.70, Cycle.custom), Plan('Monthly', 13.90)]),
  Service('Coursera Plus', 'Learning', [Plan('Monthly', 59.00), Plan('Yearly', 399.00, _y)]),
  Service('Udemy Personal Plan', 'Learning', [Plan('Monthly', 20.00)]),
  Service('Skillshare', 'Learning', [Plan('Yearly', 168.00, _y)]),
  Service('MasterClass', 'Learning', [Plan('Individual', 120.00, _y)]),
  Service('Blinkist', 'Learning', [Plan('Premium', 79.99, _y)]),
  Service('Brilliant', 'Learning', [Plan('Premium', 149.99, _y)]),
  Service('LinkedIn Premium', 'Learning', [Plan('Career', 29.99)]),
  Service('Busuu', 'Learning', [Plan('Premium', 13.99)]),
  Service('Zoom', 'Software', [Plan('Pro', 13.99)]),
  Service('Slack', 'Software', [Plan('Pro', 8.75)]),
  Service('Dropbox', 'Cloud', [Plan('Plus', 11.99), Plan('Plus yearly', 119.88, _y)]),
  Service('Google One', 'Cloud', [Plan('100 GB', 1.99), Plan('200 GB', 2.99), Plan('2 TB', 9.99)]),
  Service('iCloud+', 'Cloud', [Plan('50 GB', 0.99), Plan('200 GB', 2.99), Plan('2 TB', 9.99)]),
  Service('Apple One', 'Cloud', [Plan('Individual', 19.95), Plan('Family', 25.95)]),
  Service('OneDrive', 'Cloud', [Plan('100 GB', 2.00)]),
  Service('pCloud', 'Cloud', [Plan('Premium yearly', 49.99, _y)]),
  Service('Backblaze', 'Cloud', [Plan('Personal', 9.00)]),
  Service('Google Workspace', 'Cloud', [Plan('Business Starter', 6.80)]),
  Service('Squarespace', 'Software', [Plan('Personal yearly', 192.00, _y)]),
  Service('Wix', 'Software', [Plan('Light', 17.00)]),
  Service('Shopify', 'Software', [Plan('Basic', 36.00)]),
  Service('Domain renewal', 'Software', [Plan('Yearly', 15.00, _y)]),

  // Gaming
  Service('Xbox Game Pass', 'Gaming', [Plan('Ultimate', 17.99), Plan('Standard', 12.99), Plan('PC', 11.99)]),
  Service('PlayStation Plus', 'Gaming', [Plan('Essential', 8.99), Plan('Extra', 13.99), Plan('Premium', 16.99), Plan('Essential yearly', 71.99, _y)]),
  Service('Nintendo Switch Online', 'Gaming', [Plan('Individual', 19.99, _y), Plan('Family', 34.99, _y)]),
  Service('EA Play', 'Gaming', [Plan('Monthly', 5.99)]),
  Service('Ubisoft+', 'Gaming', [Plan('Premium', 17.99)]),
  Service('Apple Arcade', 'Gaming', [Plan('Monthly', 6.99)]),
  Service('GeForce NOW', 'Gaming', [Plan('Performance', 10.99), Plan('Ultimate', 21.99)]),
  Service('Discord Nitro', 'Gaming', [Plan('Nitro', 9.99), Plan('Basic', 2.99)]),
  Service('World of Warcraft', 'Gaming', [Plan('Monthly', 12.99)]),
  Service('Final Fantasy XIV', 'Gaming', [Plan('Standard', 12.99)]),
  Service('Roblox Premium', 'Gaming', [Plan('1000', 10.99)]),
  Service('Fortnite Crew', 'Gaming', [Plan('Monthly', 11.99)]),
  Service('Humble Choice', 'Gaming', [Plan('Monthly', 11.99)]),
  Service('Chess.com', 'Gaming', [Plan('Gold yearly', 49.99, _y)]),

  // News & reading
  Service('The New York Times', 'News', [Plan('All Access', 25.00)]),
  Service('The Economist', 'News', [Plan('Digital', 19.90)]),
  Service('The Guardian', 'News', [Plan('Supporter', 12.00)]),
  Service('Financial Times', 'News', [Plan('Standard Digital', 45.00)]),
  Service('The Washington Post', 'News', [Plan('Digital', 12.00)]),
  Service('Wall Street Journal', 'News', [Plan('Digital', 38.99)]),
  Service('Der Spiegel', 'News', [Plan('Spiegel+', 21.99)]),
  Service('Le Monde', 'News', [Plan('Digital', 12.99)]),
  Service('Medium', 'News', [Plan('Member', 5.00)]),
  Service('Substack', 'News', [Plan('Paid newsletter', 8.00)]),
  Service('Kindle Unlimited', 'News', [Plan('Monthly', 11.99)]),
  Service('Readly', 'News', [Plan('Monthly', 12.99)]),
  Service('Patreon', 'News', [Plan('Membership', 5.00)]),
  Service('Pocket Premium', 'News', [Plan('Monthly', 4.99)]),
  Service('Scribd', 'News', [Plan('Everand', 11.99)]),

  // Fitness & health
  Service('Strava', 'Fitness', [Plan('Yearly', 59.99, _y), Plan('Monthly', 9.99)]),
  Service('Peloton App', 'Fitness', [Plan('One', 12.99), Plan('Plus', 24.00)]),
  Service('Apple Fitness+', 'Fitness', [Plan('Monthly', 9.99)]),
  Service('Fitbit Premium', 'Fitness', [Plan('Monthly', 8.99)]),
  Service('Garmin Connect+', 'Fitness', [Plan('Monthly', 8.99)]),
  Service('Whoop', 'Fitness', [Plan('One yearly', 199.00, _y)]),
  Service('Oura', 'Fitness', [Plan('Membership', 5.99)]),
  Service('MyFitnessPal', 'Fitness', [Plan('Premium', 19.99)]),
  Service('Freeletics', 'Fitness', [Plan('Coach yearly', 79.99, _y)]),
  Service('Komoot', 'Fitness', [Plan('Premium yearly', 59.99, _y)]),
  Service('Zwift', 'Fitness', [Plan('Monthly', 19.99)]),
  Service('Urban Sports Club', 'Fitness', [Plan('M', 89.00), Plan('S', 59.00), Plan('L', 139.00)]),
  Service('ClassPass', 'Fitness', [Plan('Monthly', 39.00)]),
  Service('McFit', 'Fitness', [Plan('Membership', 29.90)]),
  Service('Basic-Fit', 'Fitness', [Plan('Comfort', 29.99)]),
  Service('PureGym', 'Fitness', [Plan('Core', 24.99)]),
  Service('Anytime Fitness', 'Fitness', [Plan('Membership', 39.00)]),
  Service('Gym membership', 'Fitness', [Plan('Monthly', 30.00)]),
  Service('Yoga studio', 'Fitness', [Plan('Unlimited', 89.00)]),
  Service('Flo', 'Fitness', [Plan('Premium', 9.99)]),

  // Food & delivery
  Service('HelloFresh', 'Food', [Plan('3 meals for 2', 59.99, Cycle.weekly)]),
  Service('Factor', 'Food', [Plan('8 meals', 89.92, Cycle.weekly)]),
  Service('Uber One', 'Food', [Plan('Monthly', 5.99)]),
  Service('Wolt+', 'Food', [Plan('Monthly', 7.99)]),
  Service('Deliveroo Plus', 'Food', [Plan('Gold', 5.99)]),
  Service('DoorDash DashPass', 'Food', [Plan('Monthly', 9.99)]),
  Service('Lieferando', 'Food', [Plan('Plus', 4.99)]),
  Service('Too Good To Go', 'Food', [Plan('Plus', 2.99)]),
  Service('Coffee subscription', 'Food', [Plan('Monthly bag', 18.00)]),

  // Shopping & memberships
  Service('Costco', 'Shopping', [Plan('Gold Star', 65.00, _y)]),
  Service('Walmart+', 'Shopping', [Plan('Monthly', 12.95)]),
  Service('Zalando Plus', 'Shopping', [Plan('Yearly', 20.00, _y)]),
  Service('eBay Plus', 'Shopping', [Plan('Yearly', 19.90, _y)]),
  Service('Instacart+', 'Shopping', [Plan('Monthly', 9.99)]),
  Service('Dollar Shave Club', 'Shopping', [Plan('Starter', 10.00)]),
  Service('Amazon Subscribe & Save', 'Shopping', [Plan('Monthly order', 20.00)]),

  // Phone, internet, home
  Service('Mobile phone plan', 'Phone & Internet', [Plan('Monthly', 20.00)]),
  Service('Home internet', 'Phone & Internet', [Plan('Monthly', 39.99)]),
  Service('Vodafone', 'Phone & Internet', [Plan('Mobile', 29.99), Plan('Home internet', 39.99)]),
  Service('Telekom', 'Phone & Internet', [Plan('MagentaMobil', 39.95), Plan('MagentaZuhause', 39.95)]),
  Service('O2', 'Phone & Internet', [Plan('Mobile', 19.99)]),
  Service('Orange', 'Phone & Internet', [Plan('Mobile', 19.99)]),
  Service('Google Fi', 'Phone & Internet', [Plan('Simply Unlimited', 50.00)]),
  Service('Ring Protect', 'Phone & Internet', [Plan('Basic', 3.99), Plan('Plus', 10.00)]),
  Service('Nest Aware', 'Phone & Internet', [Plan('Standard', 8.00)]),
  Service('Tile Premium', 'Phone & Internet', [Plan('Yearly', 34.99, _y)]),

  // Other
  Service('TV licence', 'Other', [Plan('Monthly', 18.36)]),
  Service('Car insurance', 'Other', [Plan('Yearly', 480.00, _y)]),
  Service('Home insurance', 'Other', [Plan('Yearly', 120.00, _y)]),
  Service('Phone insurance', 'Other', [Plan('Monthly', 7.99)]),
  Service('Parking permit', 'Other', [Plan('Yearly', 30.00, _y)]),
  Service('Public transport pass', 'Other', [Plan('Monthly', 58.00)]),
  Service('Car sharing', 'Other', [Plan('Monthly', 9.90)]),
  Service('Tinder', 'Other', [Plan('Plus', 14.99), Plan('Gold', 24.99)]),
  Service('Bumble', 'Other', [Plan('Premium', 29.99)]),
  Service('Hinge', 'Other', [Plan('HingeX', 39.99)]),
  Service('Charity donation', 'Other', [Plan('Monthly', 10.00)]),

  // Popular outside Europe. No typical euro price, so the user enters it.
  Service('JioHotstar', 'Streaming', [Plan('Mobile', null), Plan('Super', null), Plan('Premium', null)]),
  Service('ZEE5', 'Streaming', [Plan('Premium', null)]),
  Service('SonyLIV', 'Streaming', [Plan('Premium', null)]),
  Service('Shahid', 'Streaming', [Plan('VIP', null), Plan('VIP | Sports', null)]),
  Service('OSN+', 'Streaming', [Plan('Monthly', null)]),
  Service('STARZPLAY', 'Streaming', [Plan('Monthly', null)]),
  Service('Viu', 'Streaming', [Plan('Premium', null)]),
  Service('iQIYI', 'Streaming', [Plan('VIP Standard', null), Plan('VIP Premium', null)]),
  Service('Showmax', 'Streaming', [Plan('Entertainment', null), Plan('Premier League', null)]),
  Service('Stan', 'Streaming', [Plan('Standard', null), Plan('Premium', null)]),
  Service('Crave', 'Streaming', [Plan('Basic', null), Plan('Premium', null)]),
  Service('Globoplay', 'Streaming', [Plan('Padrão', null)]),
  Service('Sling TV', 'Streaming', [Plan('Orange', null), Plan('Blue', null)]),
  Service('YouTube TV', 'Streaming', [Plan('Base', null)]),
  Service('Anghami', 'Music', [Plan('Plus', null)]),
  Service('JioSaavn', 'Music', [Plan('Pro', null)]),
  Service('Gaana', 'Music', [Plan('Plus', null)]),
  Service('Boomplay', 'Music', [Plan('Premium', null)]),
  Service('Pandora', 'Music', [Plan('Plus', null), Plan('Premium', null)]),
  Service('SiriusXM', 'Music', [Plan('Music & Entertainment', null)]),
  Service('Swiggy One', 'Food', [Plan('Membership', null)]),
  Service('Zomato Gold', 'Food', [Plan('Membership', null)]),
  Service('Grubhub+', 'Food', [Plan('Monthly', null)]),
  Service('Talabat Pro', 'Food', [Plan('Monthly', null)]),
  Service('Careem Plus', 'Food', [Plan('Monthly', null)]),
  Service('Rappi Prime', 'Food', [Plan('Monthly', null)]),
  Service('Flipkart VIP', 'Shopping', [Plan('Yearly', null, _y)]),
  Service('Noon VIP', 'Shopping', [Plan('Monthly', null)]),
  Service('Mercado Libre Meli+', 'Shopping', [Plan('Monthly', null)]),
  Service('Target Circle 360', 'Shopping', [Plan('Yearly', null, _y)]),
  Service("Sam's Club", 'Shopping', [Plan('Club', null, _y)]),
  Service('Planet Fitness', 'Fitness', [Plan('Classic', null), Plan('Black Card', null)]),
  Service('Equinox', 'Fitness', [Plan('All Access', null)]),
  Service('Cult.fit', 'Fitness', [Plan('Elite', null), Plan('Pro', null)]),
  Service("Byju's", 'Learning', [Plan('Subscription', null)]),
  Service('Chegg', 'Learning', [Plan('Study', null)]),
  Service('Quizlet Plus', 'Learning', [Plan('Yearly', null, _y)]),
  Service('Cloud gaming', 'Gaming', [Plan('Monthly', 9.99)]),
  Service('Magazine', 'News', [Plan('Monthly', 6.99)]),
];

const popularNames = [
  'Netflix',
  'Spotify',
  'Disney+',
  'Amazon Prime',
  'YouTube Premium',
  'Apple Music',
  'iCloud+',
  'Max',
  'Xbox Game Pass',
  'ChatGPT Plus',
  'Microsoft 365',
  'Gym membership',
];

List<Service> get popularServices => [for (final n in popularNames) catalog.firstWhere((s) => s.name == n)];

/// Prefix matches first ("Net" → Netflix), then word starts ("Prime" →
/// Amazon Prime), then anywhere in the name.
List<Service> searchCatalog(String query, {int limit = 8}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final seen = <Service>{};
  final out = <Service>[];
  void addWhere(bool Function(String name) test) {
    for (final s in catalog) {
      if (out.length >= limit) return;
      if (!seen.contains(s) && test(s.name.toLowerCase())) {
        seen.add(s);
        out.add(s);
      }
    }
  }

  addWhere((n) => n.startsWith(q));
  addWhere((n) => n.split(RegExp(r'[\s+.\-]')).any((w) => w.startsWith(q)));
  addWhere((n) => n.contains(q));
  return out;
}

/// Finds a catalog service whose name appears in a bank statement text.
/// Full names win; a distinctive first word ("ChatGPT") is the fallback.
Service? matchService(String text) {
  String letters(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  final t = letters(text);
  Service? best;
  var bestScore = 0;
  for (final s in catalog) {
    final full = letters(s.name);
    final first = letters(s.name.split(' ').first);
    var score = 0;
    if (full.length >= 3 && t.contains(full)) {
      score = 100 + full.length;
    } else if (first.length >= 5 && t.contains(first)) {
      score = first.length;
    }
    if (score > bestScore) {
      best = s;
      bestScore = score;
    }
  }
  return best;
}
