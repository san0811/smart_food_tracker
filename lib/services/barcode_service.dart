import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_constants.dart';
import '../models/food_item.dart';

class BarcodeService {
  Future<FoodItem> fetchProduct(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Barcode cannot be empty.');
    }

    final uri = Uri.parse(
      '${AppConstants.openFoodFactsBaseUrl}/${Uri.encodeComponent(normalized)}.json',
    );

    try {
      final response = await http
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'SmartFoodTracker/1.0 (Flutter)',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception(
          'Open Food Facts request failed with status ${response.statusCode}.',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as int? ?? 0;
      if (status != 1) {
        throw Exception(
          (json['status_verbose'] as String?) ?? 'Product not found.',
        );
      }

      final product = json['product'] as Map<String, dynamic>?;
      if (product == null) {
        throw const FormatException('Product payload is missing.');
      }

      return FoodItem.fromOpenFoodFacts(barcode: normalized, product: product);
    } on SocketException {
      throw Exception(
        'Network error: unable to reach Open Food Facts. Check your internet connection or emulator DNS and try again.',
      );
    } on TimeoutException {
      throw Exception(
        'Open Food Facts took too long to respond. Please retry in a moment.',
      );
    }
  }
}
