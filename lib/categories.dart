/// Categories that are not everyday spending: money moving between the
/// user's own accounts, paying the card bill, investing, or income.
const nonSpendingCategories = {'Transfer', 'Card payment', 'Investing', 'Income'};

const categoryChoices = [
  'Food & drink',
  'Groceries',
  'Transport',
  'Shopping',
  'Subscriptions',
  'Entertainment',
  'Travel',
  'Health',
  'Fitness & sports',
  'Bills & utilities',
  'Insurance',
  'Home services',
  'Wallet top-up',
  'Refund',
  'Income',
  'Transfer',
  'Card payment',
  'Investing',
  'Uncategorised',
];

const _keywords = <String, List<String>>{
  'Transport': [
    'BUS/MRT', 'GRAB*', 'GRABTAXI', 'COMFORT', 'CABCHARGE', 'GOJEK', 'TADA',
    'SIMPLYGO', 'SHARETRANSPORT', 'BLUESG', 'ZIGZAG', 'TRANSIT LINK',
  ],
  'Groceries': [
    'NTUC', 'FAIRPRICE', 'COLD STORAGE', 'SHENG SIONG', 'GIANT', 'DON DON DONKI',
    'REDMART', 'DAIRY FARM', 'CS FRESH',
  ],
  'Food & drink': [
    'KAYA', 'COFFEE', 'TOAST', 'KOPITIAM', 'BAKE', 'BURGER', 'SUBWAY', 'KOUFU',
    'YOCHI', 'NOODLE', 'SAIZERIYA', 'LAKSA', 'PANCAKES', 'TEA HUT', 'LEMON STAND',
    'RESTAURANT', 'CAFE', 'SALAD STOP', 'BAGUETTE', 'SUBARASHII', 'GATHERFOOD',
    'DIANXIAOER', 'HUNAN', 'PIZZA', 'MCDONALD', 'KFC', 'STARBUCKS', 'SUSHI',
    'RAMEN', 'MR BEAN', 'GROUPER', 'POTATO HEROES', 'BIRDS OF PARADISE',
    'FOOD', 'EATING HOUSE', 'BBQ', 'HOTPOT', 'HOT POT', 'DRINKS', 'JUICE',
    'DELIVEROO', 'FOODPANDA', 'BUBBLE TEA', 'LIHO', 'KOI', 'GONG CHA',
    'YAKUN', 'KEISUK', 'FATTENED CALF', 'GREYBOX', 'KOPIFELLAS', 'ADAMS CORNER',
    'ASTONS', 'WASHOKU', 'WU PAO CHUN', 'DAILY CUT', 'DEWGATHER', 'SEVEN SPICES',
    'HANS -', 'TANGO', 'KING GROUPER',
  ],
  'Shopping': [
    'SHOPEE', 'LAZADA', 'AMAZON', 'DECATHLON', 'MR DIY', 'MINISO', 'TAOBAO',
    'UNIQLO', 'IKEA', 'DAISO',
  ],
  'Subscriptions': [
    'NETFLIX', 'SPOTIFY', 'HBOMAX', 'OPENAI', 'CHATGPT', 'ANTHROPIC', 'CLAUDE',
    'APPLE.COM/BILL', 'YOUTUBE', 'DISNEY', 'ICLOUD', 'GOOGLE ONE', 'PRIME VIDEO',
  ],
  'Entertainment': [
    'SHAW THEATRES', 'CINEMA', 'STEAMGAMES', 'BLIZZARD', 'GOLDEN VILLAGE',
    'PLAYSTATION', 'NINTENDO', 'KLOOK',
  ],
  'Travel': [
    'AIRBNB', 'VUELING', 'TRAINLINE', 'THE AIRLINE', 'AIRLINES', 'SCOOT',
    'AGODA', 'BOOKING.COM', 'HOTEL', 'EUROPEAN MONETARY', 'EXPEDIA', 'CHANGI',
  ],
  'Health': [
    'POLYCLINIC', 'CLINIC', 'PHARMACY', 'GUARDIAN', 'WATSONS', 'HOSPITAL',
    'DENTAL',
  ],
  'Fitness & sports': [
    'FITNESS FIRST', 'AVID SPORTS', 'ACTIVESG', 'SPORTS HUB', 'SG NTL STADIUM',
    'ANYTIME FITNESS', 'GYM',
  ],
  'Bills & utilities': [
    'SP DIGITAL', 'SP UNO', 'SP SERVICES', 'SINGTEL', 'STARHUB', 'SIMBA',
    'CIRCLES.LIFE', 'MYREPUBLIC', 'PUB ',
  ],
  'Insurance': [
    'SINGAPORE LIFE', 'SINGLIFE', 'AIA', 'PRUDENTIAL', 'GREAT EASTERN',
    'INCOME INSURANCE', 'MANULIFE',
  ],
  'Home services': ['HELPLING', 'URBAN COMPANY'],
};

/// The part of a transaction that identifies who it was with: the card
/// merchant, or the counterparty line of a bank transaction.
String merchantLabel(String description, String detail, String source) {
  if (source != 'bank') return description;
  final lines = detail.isEmpty ? <String>[] : detail.split(' | ');
  for (final line in lines) {
    final m = RegExp(r'^(?:TO|FROM):\s*(.+)$').firstMatch(line);
    if (m != null) return m.group(1)!;
  }
  if (lines.any((l) => l.toUpperCase().contains('TOP-UP TO PAYLAH'))) {
    return 'PayLah! top-up';
  }
  if (lines.isNotEmpty) return lines.first;
  return description;
}

/// A stable key for a merchant: reference numbers and long codes removed, so
/// "BUS/MRT 926260912" and "BUS/MRT 927510051" are the same merchant.
String merchantKey(String label) {
  final tokens = label
      .toUpperCase()
      .split(RegExp(r'\s+'))
      .where((t) => !(t.length >= 4 && RegExp(r'\d').hasMatch(t)))
      .toList();
  return tokens.join(' ').trim();
}

/// Works out the category of a transaction. [userRules] (merchant key ->
/// category) the user set always win. [ownAccountNumbers] let money moving
/// between the user's own accounts be recognised.
String categorize({
  required String source,
  required double amount,
  required String description,
  required String detail,
  Set<String> ownAccountNumbers = const {},
  Map<String, String> userRules = const {},
}) {
  final label = merchantLabel(description, detail, source);
  final key = merchantKey(label);
  final rule = key.isEmpty ? null : userRules[key];
  if (rule != null) return rule;

  final text = '$description $detail'.toUpperCase();

  if (text.contains('BILL PAYMENT - DBS INTERNET') || text.contains('DBSC-')) {
    return 'Card payment';
  }
  if (text.contains('INTERACTIVE BR') || text.contains('IBKR')) {
    return 'Investing';
  }
  if (ownAccountNumbers.any(text.contains)) return 'Transfer';
  if (text.contains('SALARY')) return 'Income';
  if (text.contains('TOP-UP TO PAYLAH')) return 'Wallet top-up';

  for (final entry in _keywords.entries) {
    if (entry.value.any(text.contains)) return entry.key;
  }

  // Money in from an internet-banking transfer is a transfer, not income.
  if (amount > 0 && source == 'bank' && text.contains('IB:')) return 'Transfer';
  if (amount > 0) return source == 'bank' ? 'Income' : 'Refund';
  return 'Uncategorised';
}
