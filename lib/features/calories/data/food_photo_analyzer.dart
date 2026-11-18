import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/services/firebase_config.dart';

class FoodPhotoEstimate {
  const FoodPhotoEstimate({
    required this.name,
    required this.servingDescription,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String name;
  final String servingDescription;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

class FoodPhotoAnalyzer {
  const FoodPhotoAnalyzer();

  Future<FoodPhotoEstimate> estimate({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    if (!FirebaseConfig.isConfigured || Firebase.apps.isEmpty) {
      throw const FoodPhotoSetupException();
    }

    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.8-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
      ),
    );
    final prompt = TextPart('''
Analyze this meal photo for a food tracking app in Indonesia.
Estimate the visible food as one realistic serving (or the whole visible plate).
Return ONLY a JSON object with exactly these fields:
{"name":"short Indonesian food name","servingDescription":"estimated serving in Indonesian","calories":0,"protein":0,"carbs":0,"fat":0}
Nutrient values must be numeric grams for macros and kcal for calories. Use sensible estimates from visible portion size, include cooking oil/sauce where likely, and do not claim precision. If no food is visible, set name to "" and all numeric values to 0.
''');
    final response = await model.generateContent([
      Content.multi([prompt, InlineDataPart(mimeType, imageBytes)]),
    ]);
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw const FoodPhotoAnalysisException('AI tidak mengembalikan hasil.');
    }

    try {
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final name = (decoded['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        throw const FoodPhotoAnalysisException(
          'Makanan tidak terlihat jelas. Coba foto ulang dengan makanan memenuhi gambar.',
        );
      }
      double number(String key) {
        final value = decoded[key];
        if (value is num && value.isFinite && value >= 0) {
          return value.toDouble();
        }
        return 0;
      }

      return FoodPhotoEstimate(
        name: name,
        servingDescription:
            (decoded['servingDescription'] as String? ?? '1 porsi').trim(),
        calories: number('calories').clamp(0, 5000).toDouble(),
        protein: number('protein').clamp(0, 500).toDouble(),
        carbs: number('carbs').clamp(0, 1000).toDouble(),
        fat: number('fat').clamp(0, 500).toDouble(),
      );
    } on FoodPhotoAnalysisException {
      rethrow;
    } catch (_) {
      throw const FoodPhotoAnalysisException(
        'Hasil foto belum terbaca. Coba ambil foto makanan sekali lagi.',
      );
    }
  }
}

class FoodPhotoSetupException implements Exception {
  const FoodPhotoSetupException();

  @override
  String toString() => 'Fitur foto perlu dihubungkan ke project Firebase dulu.';
}

class FoodPhotoAnalysisException implements Exception {
  const FoodPhotoAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}
