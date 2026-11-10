import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

/// Error shown on the offline / error screen. [message] is ready for the UI.
class ProductApiException implements Exception {
  final String message;
  final int? statusCode;

  const ProductApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Loads products from https://fakestoreapi.com (LW10).
///
/// The [http.Client] is injectable, so tests use `MockClient` and never
/// touch the network.
class ProductApi {
  static final productsUri = Uri.parse('https://fakestoreapi.com/products');
  static const timeout = Duration(seconds: 10);

  final http.Client _client;

  ProductApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _client.get(productsUri).timeout(timeout);

      switch (response.statusCode) {
        case 200:
          // utf8 decode, so non-ASCII text is not garbled.
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data is! List) {
            throw const FormatException('Expected a JSON list');
          }
          return data
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList();
        case 404:
          throw const ProductApiException(
            'Каталог не найден (404)',
            statusCode: 404,
          );
        case >= 500:
          throw ProductApiException(
            'Сервер магазина недоступен (${response.statusCode}). '
            'Попробуйте позже.',
            statusCode: response.statusCode,
          );
        default:
          throw ProductApiException(
            'Неожиданный ответ сервера (${response.statusCode})',
            statusCode: response.statusCode,
          );
      }
    } on TimeoutException {
      throw const ProductApiException(
        'Сервер не ответил за 10 секунд. Проверьте интернет.',
      );
    } on http.ClientException {
      // No network, DNS failure, airplane mode (SocketException inside).
      throw const ProductApiException(
        'Нет подключения к интернету. Выключите авиарежим или '
        'подключитесь к Wi‑Fi.',
      );
    } on FormatException {
      throw const ProductApiException('Сервер прислал некорректные данные.');
    } on ProductApiException {
      rethrow;
    } catch (_) {
      // TLS errors and anything else: still a friendly message + Retry.
      throw const ProductApiException('Не удалось загрузить товары.');
    }
  }
}
