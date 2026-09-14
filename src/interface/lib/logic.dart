part of 'main.dart';

Future<_ForecastSnapshot> _loadForecastSnapshot() async {
  final approvalRating = await _loadApprovalRating();
  final ballot = await _loadBallot();

  final inferenceService = InferenceService(
    config: const InferenceConfig(
      modelPath: 'inference/model.json',
      inputPath: 'inference/current_stats',
    ),
  );

  final result = await inferenceService.runInference({
    'misery_index': 0.0,
    'approval_rating': approvalRating,
    'ballot': ballot,
  });

  final nationalLean = (result.data['prediction'] as num).toDouble();

  final pollingRows = await _loadPollingRows();
  final statePviRows = await _loadStatePviRows();

  final states = <StateForecast>[];
  for (final row in statePviRows) {
    final calibration = row.pvi2022 + nationalLean;
    states.add(
      StateForecast(
        stateCode: row.stateCode,
        pvi2022: row.pvi2022,
        forecast: calibration,
        pollingAverage: pollingRows[row.stateCode],
      ),
    );
  }

  states.sort((left, right) => left.stateCode.compareTo(right.stateCode));

  return _ForecastSnapshot(
    nationalLean: nationalLean,
    approvalRating: approvalRating,
    ballot: ballot,
    states: states,
  );
}

Future<double> _loadApprovalRating() async {
  final currentStats = await rootBundle.loadString('inference/current_stats');
  final lines = LineSplitter.split(
    currentStats,
  ).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

  final approval = double.tryParse(lines[0]);
  if (approval == null) {
    throw const FormatException(
      'Could not parse approval rating from current_stats.',
    );
  }

  return approval;
}

Future<double> _loadBallot() async {
  final currentStats = await rootBundle.loadString('inference/current_stats');
  final lines = LineSplitter.split(
    currentStats,
  ).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

  final ballot = double.tryParse(lines[1]);
  if (ballot == null) {
    throw const FormatException(
      'Could not parse generic ballot from current_stats.',
    );
  }

  return ballot;
}

Future<Map<String, double>> _loadPollingRows() async {
  final raw = await rootBundle.loadString('inference/current_polling.csv');
  final rows = LineSplitter.split(raw)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .skip(1)
      .toList();

  final polling = <String, double>{};

  for (final row in rows) {
    final values = row.split(',');
    if (values.length != 2) {
      continue;
    }

    final stateCode = values[0].trim();
    final averageValue = double.tryParse(values[1].trim());
    if (stateCode.isNotEmpty && averageValue != null) {
      polling[stateCode] = averageValue;
    }
  }

  return polling;
}

Future<List<_StatePviRow>> _loadStatePviRows() async {
  final raw = await rootBundle.loadString('inference/state_pvi_midterms.csv');
  final rows = LineSplitter.split(raw)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .skip(1)
      .toList();

  final data = <_StatePviRow>[];

  for (final row in rows) {
    final values = row.split(',');
    if (values.length != 2) {
      continue;
    }

    final stateCode = values[0].trim();
    final pvi = double.tryParse(values[1].trim());

    if (stateCode.isNotEmpty && pvi != null) {
      data.add(_StatePviRow(stateCode: stateCode, pvi2022: pvi));
    }
  }

  return data;
}

double _pollingWeight() {
  final forecastStartDate = DateTime(2026, 9, 12);
  final electionDay = DateTime(2026, 11, 3);

  final totalDays = electionDay.difference(forecastStartDate).inDays;
  if (totalDays <= 0) {
    return 0.7;
  }

  final now = DateTime.now();
  if (now.isBefore(forecastStartDate)) {
    return 0.35;
  }

  final elapsedDays = now.difference(forecastStartDate).inDays;
  final progress = (elapsedDays / totalDays).clamp(0.0, 1.0);

  return (0.35 + (0.35 * progress)).clamp(0.35, 0.7);
}

String forecastCatergory(double forecast) {
  final abs = forecast.abs();
  final dorr = forecast >= 0 ? 'D' : 'R';

  if (abs < 2) {
    return 'Tilt $dorr';
  } else if (abs < 5) {
    return 'Lean $dorr';
  } else if (abs < 10) {
    return 'Likely $dorr';
  } else {
    return 'Safe $dorr';
  }
}
