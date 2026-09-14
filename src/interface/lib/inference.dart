/// Inference module for the Flutter app.
///
/// This service loads the serialized model from the app assets and applies the
/// same normalization and prediction logic used by the Python pipeline.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

class InferenceConfig {
  const InferenceConfig({
    this.modelPath = 'inference/model.json',
    this.inputPath = 'inference/current_stats',
    this.fallbackMiseryIndex = 0.0,
  });

  final String modelPath;
  final String inputPath;
  final double fallbackMiseryIndex;
}

class InferenceResult {
  const InferenceResult({
    required this.status,
    required this.metadata,
    this.data,
  });

  final String status;
  final Map<String, dynamic> metadata;
  final dynamic data;
}

class InferenceService {
  const InferenceService({this.config = const InferenceConfig()});

  final InferenceConfig config;

  InferenceConfig loadConfig() {
    return config;
  }

  List<double> prepareInputs(dynamic rawInput) {
    if (rawInput is List) {
      final values = rawInput
          .map((item) => (item as num).toDouble())
          .toList(growable: false);

      if (values.length == 3) {
        return values;
      }

      if (values.length == 2) {
        return [config.fallbackMiseryIndex, values[0], values[1]];
      }
    }

    if (rawInput is Map<String, dynamic>) {
      final values = [
        rawInput['misery_index'] ??
            rawInput['miseryIndex'] ??
            config.fallbackMiseryIndex,
        rawInput['approval_rating'] ?? rawInput['approvalRating'] ?? 0,
        rawInput['ballot'] ?? rawInput['genericBallot'] ?? 0,
      ];

      return values
          .map((item) => (item as num).toDouble())
          .toList(growable: false);
    }

    if (rawInput is String) {
      final parsedValues = rawInput
          .split(RegExp(r'[\s,]+'))
          .where((item) => item.isNotEmpty)
          .map((item) => double.tryParse(item))
          .whereType<double>()
          .toList(growable: false);

      if (parsedValues.length == 3) {
        return parsedValues;
      }

      if (parsedValues.length == 2) {
        return [config.fallbackMiseryIndex, parsedValues[0], parsedValues[1]];
      }
    }

    throw ArgumentError.value(
      rawInput,
      'rawInput',
      'Expected a 3-value feature vector or a map with model feature names.',
    );
  }

  Future<InferenceResult> runInference(dynamic rawInput) async {
    final loadedInput = rawInput ?? await _loadDefaultInput();
    final preparedInput = prepareInputs(loadedInput);

    if (preparedInput.length != 3) {
      throw StateError(
        'Expected three feature values: misery_index, approval_rating, ballot.',
      );
    }

    final model = await _loadModel();

    final scaler = model['scaler'] as Map<String, dynamic>;
    final modelData = model['model'] as Map<String, dynamic>;

    final means = (scaler['mean'] as List<dynamic>)
        .map((item) => (item as num).toDouble())
        .toList();
    final scales = (scaler['scale'] as List<dynamic>)
        .map((item) => (item as num).toDouble())
        .toList();
    final coefficients = (modelData['coefficients'] as List<dynamic>)
        .map((item) => (item as num).toDouble())
        .toList();
    final intercept = (modelData['intercept'] as num).toDouble();
    final featureNames = (scaler['feature_names'] as List<dynamic>)
        .cast<String>();

    final scaledFeatures = <double>[];
    for (var index = 0; index < preparedInput.length; index++) {
      final feature = preparedInput[index];
      final mean = means[index];
      final scale = scales[index];
      scaledFeatures.add((feature - mean) / scale);
    }

    final prediction = _dotProduct(scaledFeatures, coefficients) + intercept;

    return InferenceResult(
      status: 'ok',
      metadata: {
        'modelPath': config.modelPath,
        'inputPath': config.inputPath,
        'featureNames': featureNames,
        'modelAlpha': modelData['alpha'],
        'intercept': intercept,
      },
      data: {
        'features': preparedInput,
        'scaledFeatures': scaledFeatures,
        'featureNames': featureNames,
        'prediction': prediction,
      },
    );
  }

  Future<Map<String, dynamic>> _loadModel() async {
    final rawJson = await rootBundle.loadString(config.modelPath);
    final decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Model JSON must decode to an object.');
    }

    return decoded;
  }

  Future<dynamic> _loadDefaultInput() async {
    try {
      final rawInput = await rootBundle.loadString(config.inputPath);
      final lines = rawInput
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);

      if (lines.length >= 2) {
        final approval = double.tryParse(lines[0]);
        final ballot = double.tryParse(lines[1]);

        if (approval != null && ballot != null) {
          return {
            'misery_index': config.fallbackMiseryIndex,
            'approval_rating': approval,
            'ballot': ballot,
          };
        }
      }
    } catch (_) {
      // Fall back to the configured default input below.
    }

    return {
      'misery_index': config.fallbackMiseryIndex,
      'approval_rating': 0.0,
      'ballot': 0.0,
    };
  }

  double _dotProduct(List<double> a, List<double> b) {
    var total = 0.0;
    for (var index = 0; index < a.length; index++) {
      total += a[index] * b[index];
    }
    return total;
  }
}
