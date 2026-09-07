/// Gets current model feature values from FRED.
import 'dart:convert';
import 'dart:io';

const String _fredBaseUrl = 'https://api.stlouisfed.org/fred/series/observations';

Future<String> _readApiKey() async {
  final keyFile = File('src/model/inference/.key');
  return (await keyFile.readAsString()).trim();
}

Future<Map<DateTime, double>> _getSeries(
  String seriesId,
  String apiKey,
) async {
  final uri = Uri.parse(_fredBaseUrl).replace(queryParameters: {
    'series_id': seriesId,
    'api_key': apiKey,
    'file_type': 'json',
  });

  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();

  if (response.statusCode != HttpStatus.ok) {
    throw HttpException(
      'FRED request failed for $seriesId: ${response.statusCode}',
    );
  }

  final observations = (jsonDecode(body) as Map<String, dynamic>)['observations']
      as List<dynamic>;
  final values = <DateTime, double>{};

  for (final observation in observations) {
    final item = observation as Map<String, dynamic>;
    final value = double.tryParse(item['value'] as String);
    if (value != null) {
      values[DateTime.parse(item['date'] as String)] = value;
    }
  }

  return values;
}

/// Computes the current misery index from CPI inflation and unemployment.
Future<double> computeCurrentMisery() async {
  final apiKey = await _readApiKey();
  final unemployment = await _getSeries('UNRATE', apiKey);
  final cpi = await _getSeries('CPIAUCNS', apiKey);
  final dates = cpi.keys.toList()..sort();

  double? latestMisery;
  for (var index = 12; index < dates.length; index++) {
    final currentDate = dates[index];
    final previousDate = dates[index - 12];
    final unemploymentValue = unemployment[currentDate];
    final currentCpi = cpi[currentDate];
    final previousCpi = cpi[previousDate];

    if (unemploymentValue != null &&
        currentCpi != null &&
        previousCpi != null) {
      final inflation = ((currentCpi / previousCpi) - 1) * 100;
      latestMisery = unemploymentValue + inflation;
    }
  }

  if (latestMisery == null) {
    throw StateError('FRED returned insufficient overlapping data.');
  }

  return _roundToTwoDecimals(latestMisery);
}

double _roundToTwoDecimals(double value) => (value * 100).round() / 100;

/// Generic-ballot retrieval is not implemented because no API was selected.
Future<double?> getGenballot() async => null;

Future<void> main() async {
  final misery = await computeCurrentMisery();
  print('Current misery index: $misery');
}
