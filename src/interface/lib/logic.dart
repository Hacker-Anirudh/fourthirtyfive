part of 'main.dart';

Future<_ForecastSnapshot> _loadForecastSnapshot() async {
  final approvalRating = await loadApprovalRating();
  final ballot = await loadBallot();

  final Map<String, String> stateCodeTranslation = {
    'AL': 'Alabama',
    'AK': 'Alaska',
    'AZ': 'Arizona',
    'AR': 'Arkansas',
    'CA': 'California',
    'CO': 'Colorado',
    'CT': 'Connecticut',
    'DE': 'Delaware',
    'FL': 'Florida',
    'GA': 'Georgia',
    'HI': 'Hawaii',
    'ID': 'Idaho',
    'IL': 'Illinois',
    'IN': 'Indiana',
    'IA': 'Iowa',
    'KS': 'Kansas',
    'KY': 'Kentucky',
    'LA': 'Louisiana',
    'ME': 'Maine',
    'MD': 'Maryland',
    'MA': 'Massachusetts',
    'MI': 'Michigan',
    'MN': 'Minnesota',
    'MS': 'Mississippi',
    'MO': 'Missouri',
    'MT': 'Montana',
    'NE': 'Nebraska',
    'NV': 'Nevada',
    'NH': 'New Hampshire',
    'NJ': 'New Jersey',
    'NM': 'New Mexico',
    'NY': 'New York',
    'NC': 'North Carolina',
    'ND': 'North Dakota',
    'OH': 'Ohio',
    'OK': 'Oklahoma',
    'OR': 'Oregon',
    'PA': 'Pennsylvania',
    'RI': 'Rhode Island',
    'SC': 'South Carolina',
    'SD': 'South Dakota',
    'TN': 'Tennessee',
    'TX': 'Texas',
    'UT': 'Utah',
    'VT': 'Vermont',
    'VA': 'Virginia',
    'WA': 'Washington',
    'WV': 'West Virginia',
    'WI': 'Wisconsin',
    'WY': 'Wyoming',
  };

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

  final pollingRows = await loadPollingRows();
  final statePviRows = await loadStatePviRows();

  final states = <StateForecast>[];
  for (final row in statePviRows) {
    final calibration = row.pvi2022 + nationalLean;
    final stateCode = row.stateCode;
    states.add(
      StateForecast(
        stateCode: stateCodeTranslation[stateCode] ?? stateCode,
        pvi2022: row.pvi2022,
        forecast: calibration,
        pollingAverage: pollingRows[stateCode],
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

Future<double> loadApprovalRating() async {
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

Future<double> loadBallot() async {
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

Future<Map<String, double>> loadPollingRows() async {
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

// ignore: library_private_types_in_public_api
Future<List<_StatePviRow>> loadStatePviRows() async {
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

double pollingWeight() {
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

double stateForecastValue(StateForecast state, double pollingWeight) {
  if (state.pollingAverage == null) {
    return state.forecast;
  }

  return (state.forecast * (1 - pollingWeight)) +
      (state.pollingAverage! * pollingWeight);
}

Color stateCardColor(double forecast) {
  final demorrep = forecast > 0;
  forecast = forecast.abs();

  if (forecast < 2) {
    return demorrep ? const Color(0xFFB9D7FF) : const Color(0xFFF2B3BE);
  } else if (forecast < 5) {
    return demorrep ? const Color(0xFF4389E3) : const Color(0xFFCC2F4A);
  } else if (forecast < 10) {
    return demorrep ? const Color(0xFF0645B4) : const Color(0xFFAA0000);
  } else {
    return demorrep ? const Color(0xFF002B84) : const Color(0xFF800000);
  }
}

Color textColorForAccent(Color accentColor) {
  return accentColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
}

String formatSignedPercent(double value) {
  final suffix = value >= 0 ? '+' : '-';
  final absoluteValue = value.abs();
  final formatted = absoluteValue.toStringAsFixed(1);
  return '$suffix$formatted%';
}
