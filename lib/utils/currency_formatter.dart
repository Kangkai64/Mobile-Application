import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

enum Currency {
  myr('MYR', 'RM'),
  usd('USD', '\$'),
  eur('EUR', '€'),
  gbp('GBP', '£'),
  sgd('SGD', 'S\$'),
  jpy('JPY', '¥'),
  cny('CNY', '¥'),
  thb('THB', '฿'),
  idr('IDR', 'Rp');

  const Currency(this.code, this.symbol);
  final String code;
  final String symbol;
}

class ExchangeRates {
  final Map<String, double> rates;
  final DateTime lastUpdated;

  ExchangeRates({required this.rates, required this.lastUpdated});

  factory ExchangeRates.fromJson(Map<String, dynamic> json) {
    return ExchangeRates(
      rates: Map<String, double>.from(json['rates']),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000),
    );
  }
}

class CurrencyConverter {
  static ExchangeRates? _cachedRates;
  static const String _baseUrl = 'https://api.exchangerate-api.com/v6/latest';

  // Fallback rates (you should update these periodically)
  static const Map<String, double> _fallbackRates = {
    'USD': 1.0,
    'MYR': 4.72,
    'EUR': 0.92,
    'GBP': 0.79,
    'SGD': 1.35,
    'JPY': 149.50,
    'CNY': 7.24,
    'THB': 36.85,
    'IDR': 15420.0,
  };

  /// Fetches latest exchange rates from API
  static Future<ExchangeRates?> _fetchExchangeRates() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/USD'),
        headers: {'timeout': '10'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ExchangeRates.fromJson(data);
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
    }
    return null;
  }

  /// Gets exchange rates with caching
  static Future<Map<String, double>> getExchangeRates() async {
    // Check if cached rates are still valid (within 1 hour)
    if (_cachedRates != null &&
        DateTime.now().difference(_cachedRates!.lastUpdated).inHours < 1) {
      return _cachedRates!.rates;
    }

    // Try to fetch new rates
    final newRates = await _fetchExchangeRates();
    if (newRates != null) {
      _cachedRates = newRates;
      return newRates.rates;
    }

    // Fall back to cached rates if available
    if (_cachedRates != null) {
      return _cachedRates!.rates;
    }

    // Use fallback rates as last resort
    return _fallbackRates;
  }

  /// Converts amount from one currency to another
  static Future<double> convert({
    required double amount,
    required Currency from,
    required Currency to,
  }) async {
    if (from == to) return amount;

    final rates = await getExchangeRates();

    // Convert to USD first, then to target currency
    final fromRate = rates[from.code] ?? 1.0;
    final toRate = rates[to.code] ?? 1.0;

    final usdAmount = amount / fromRate;
    return usdAmount * toRate;
  }

  /// Gets the exchange rate between two currencies
  static Future<double> getRate({
    required Currency from,
    required Currency to,
  }) async {
    return await convert(amount: 1.0, from: from, to: to);
  }
}

class CurrencyFormatter {
  static final Map<Currency, NumberFormat> _formatters = {};

  /// Detects the device locale and returns the appropriate currency
  static Currency getDeviceCurrency() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final countryCode = locale.countryCode?.toUpperCase();
    
    switch (countryCode) {
      case 'MY':
        return Currency.myr;
      case 'US':
        return Currency.usd;
      case 'GB':
        return Currency.gbp;
      case 'SG':
        return Currency.sgd;
      case 'JP':
        return Currency.jpy;
      case 'CN':
        return Currency.cny;
      case 'TH':
        return Currency.thb;
      case 'ID':
        return Currency.idr;
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
      case 'NL':
      case 'BE':
      case 'AT':
      case 'LU':
      case 'IE':
      case 'PT':
      case 'FI':
      case 'GR':
      case 'CY':
      case 'MT':
      case 'SK':
      case 'SI':
      case 'EE':
      case 'LV':
      case 'LT':
        return Currency.eur;
      default:
        return Currency.myr; // Default to MYR
    }
  }

  /// Gets or creates a number formatter for the specified currency
  static NumberFormat _getFormatter(Currency currency) {
    return _formatters.putIfAbsent(currency, () {
      String locale = 'ms_MY'; // Default locale

      // Set appropriate locale for currency
      switch (currency) {
        case Currency.myr:
          locale = 'ms_MY';
          break;
        case Currency.usd:
          locale = 'en_US';
          break;
        case Currency.eur:
          locale = 'de_DE';
          break;
        case Currency.gbp:
          locale = 'en_GB';
          break;
        case Currency.sgd:
          locale = 'en_SG';
          break;
        case Currency.jpy:
          locale = 'ja_JP';
          break;
        case Currency.cny:
          locale = 'zh_CN';
          break;
        case Currency.thb:
          locale = 'th_TH';
          break;
        case Currency.idr:
          locale = 'id_ID';
          break;
      }

      return NumberFormat.currency(
        symbol: currency.symbol,
        decimalDigits: currency == Currency.jpy || currency == Currency.idr
            ? 0
            : 2,
        locale: locale,
      );
    });
  }

  /// Formats amount in the specified currency
  static String format(double amount, {Currency currency = Currency.myr}) {
    return _getFormatter(currency).format(amount);
  }

  /// Formats nullable amount in the specified currency
  static String formatNullable(double? amount,
      {Currency currency = Currency.myr}) {
    if (amount == null) return '${currency.symbol}0${currency == Currency.jpy ||
        currency == Currency.idr ? '' : '.00'}';
    return format(amount, currency: currency);
  }

  /// Formats and converts currency with exchange rate info
  static Future<String> formatWithConversion({
    required double amount,
    required Currency from,
    required Currency to,
    bool showRate = false,
  }) async {
    final convertedAmount = await CurrencyConverter.convert(
      amount: amount,
      from: from,
      to: to,
    );

    final originalFormatted = format(amount, currency: from);
    final convertedFormatted = format(convertedAmount, currency: to);

    if (showRate) {
      final rate = await CurrencyConverter.getRate(from: from, to: to);
      return '$originalFormatted = $convertedFormatted (Rate: ${rate
          .toStringAsFixed(4)})';
    }

    return '$originalFormatted → $convertedFormatted';
  }

  /// Formats amount with automatic currency conversion based on device locale
  /// If device locale is not MYR, converts from MYR to device currency
  static Future<String> formatWithAutoConversion(double amount) async {
    final deviceCurrency = getDeviceCurrency();
    
    // If device currency is MYR, just format normally
    if (deviceCurrency == Currency.myr) {
      return format(amount, currency: Currency.myr);
    }
    
    // Convert from MYR to device currency
    final convertedAmount = await CurrencyConverter.convert(
      amount: amount,
      from: Currency.myr,
      to: deviceCurrency,
    );
    
    return format(convertedAmount, currency: deviceCurrency);
  }

  /// Formats nullable amount with automatic currency conversion
  static Future<String> formatNullableWithAutoConversion(double? amount) async {
    if (amount == null) {
      final deviceCurrency = getDeviceCurrency();
      return '${deviceCurrency.symbol}0${deviceCurrency == Currency.jpy ||
          deviceCurrency == Currency.idr ? '' : '.00'}';
    }
    return formatWithAutoConversion(amount);
  }
}