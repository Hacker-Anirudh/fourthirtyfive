import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'inference.dart';

part 'logic.dart';

final double miseryIndex = -1.2;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FourThirtyFive',
      theme: ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        scaffoldBackgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
      ),
      home: MyHomePage(
        title: 'FourThirtyFive Senate forecast',
        isDark: isDark,
        onThemeToggle: () => setState(() => isDark = !isDark),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.isDark,
    required this.onThemeToggle,
    this.onResetStyle,
  });

  final bool isDark;
  final VoidCallback onThemeToggle;
  final VoidCallback? onResetStyle;

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<_ForecastSnapshot> _forecastFuture;
  final DateTime _forecastStartDate = DateTime(2026, 9, 12);
  late DateTime _selectedDate;
  final DateTime _electionDay = DateTime(2026, 11, 3);

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    if (_selectedDate.isBefore(_forecastStartDate)) {
      _selectedDate = _forecastStartDate;
    }
    if (_selectedDate.isAfter(_electionDay)) {
      _selectedDate = _electionDay;
    }
    _forecastFuture = _loadForecastSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        scrolledUnderElevation: 1,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'About',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'FourThirtyFive',
                applicationLegalese:
                    'BSD 3-Clause license. Copyright 2020-2026 Anirudh Menon. All rights reserved.',
                applicationVersion: '0.0.1',
              );
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return Theme.of(context).colorScheme.surfaceContainerHighest;
                }
                return Colors.transparent;
              }),
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_ForecastSnapshot>(
          future: _forecastFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        showElectionPopup(
                          context,
                          '2026_United_States_Senate_election_in_Texas',
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to load forecast data.',
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final forecast = snapshot.data!;
            final tiltStates = forecast.states.where((state) {
              final currentPollingWeight = pollingWeightForDate(_selectedDate);
              final displayedForecast = stateForecastValue(
                state,
                currentPollingWeight,
              );
              return displayedForecast.abs() < 2;
            }).toList();

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Senate outlook',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ForecastSummaryCard(
                      nationalLean: forecast.nationalLean,
                      approvalRating: forecast.approvalRating,
                      ballot: forecast.ballot,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forecast date',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'As time goes on polling is weighted more heavily, the slider is included so you can analyze how it would evolve if polling stayed the same.',
                              ),
                              Padding(padding: EdgeInsets.all(8.0)),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedDate = DateTime.now();
                                  });
                                },
                                child: Text('Today'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedDate.toLocal().toString().split(' ')[0],
                            style: theme.textTheme.bodyLarge,
                          ),
                          Slider(
                            min: _forecastStartDate.millisecondsSinceEpoch
                                .toDouble(),
                            max: _electionDay.millisecondsSinceEpoch.toDouble(),
                            value: _selectedDate.millisecondsSinceEpoch
                                .toDouble(),
                            divisions: _electionDay
                                .difference(_forecastStartDate)
                                .inDays,
                            label: _selectedDate.toLocal().toString().split(
                              ' ',
                            )[0],
                            onChanged: (value) {
                              setState(() {
                                _selectedDate =
                                    DateTime.fromMillisecondsSinceEpoch(
                                      value.toInt(),
                                    );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (tiltStates.isNotEmpty) ...[
                      Text(
                        'Races to watch',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final state in tiltStates)
                            () {
                              final displayedForecast = stateForecastValue(
                                state,
                                pollingWeightForDate(_selectedDate),
                              );
                              final accentColor = stateCardColor(
                                displayedForecast,
                              );
                              final textColor = textColorForAccent(accentColor);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${state.stateCode} ${formatSignedPercent(displayedForecast)}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }(),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'State forecasts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisExtent: 208,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: forecast.states.length,
                      itemBuilder: (context, index) {
                        final state = forecast.states[index];
                        final currentPollingWeight = pollingWeightForDate(
                          _selectedDate,
                        );
                        final displayedForecast = stateForecastValue(
                          state,
                          currentPollingWeight,
                        );
                        final accentColor = stateCardColor(displayedForecast);
                        final textColor = textColorForAccent(accentColor);

                        return Card(
                          elevation: 0,
                          color: accentColor,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1.5, color: accentColor),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: InkWell(
                            onTap: () {
                              showElectionPopup(
                                context,
                                '2026_United_States_Senate_election_in_${state.stateCode}',
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          state.stateCode,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                color: textColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              formatSignedPercent(
                                                displayedForecast,
                                              ),
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            Text(
                                              forecastCatergory(
                                                displayedForecast,
                                              ),
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Polling avg',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.pollingAverage != null
                                        ? state.pollingAverage!.toStringAsFixed(
                                            1,
                                          )
                                        : 'Unavailable',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '2022 PVI',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatSignedPercent(state.pvi2022),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onThemeToggle,
        tooltip: 'Toggle color mode',
        child: Icon(
          widget.isDark ? Icons.brightness_2_outlined : Icons.wb_sunny_outlined,
        ),
      ),
    );
  }
}

class _ForecastSnapshot {
  const _ForecastSnapshot({
    required this.nationalLean,
    required this.approvalRating,
    required this.ballot,
    required this.states,
  });

  final double nationalLean;
  final double approvalRating;
  final double ballot;
  final List<StateForecast> states;
}

class StateForecast {
  const StateForecast({
    required this.stateCode,
    required this.pvi2022,
    required this.forecast,
    required this.pollingAverage,
  });

  final String stateCode;
  final double pvi2022;
  final double forecast;
  final double? pollingAverage;
}

class _StatePviRow {
  const _StatePviRow({required this.stateCode, required this.pvi2022});

  final String stateCode;
  final double pvi2022;
}

class _ForecastSummaryCard extends StatelessWidget {
  const _ForecastSummaryCard({
    required this.nationalLean,
    required this.approvalRating,
    required this.ballot,
  });

  final double nationalLean;
  final double approvalRating;
  final double ballot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Current forecast',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'National lean ${_formatSignedPercent(nationalLean)}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryMetric(
                  label: 'Presidential approval',
                  value: '${approvalRating.toStringAsFixed(1)}%',
                ),
                _SummaryMetric(
                  label: 'Generic ballot',
                  value: '${ballot.toStringAsFixed(1)}%',
                ),
                _SummaryMetric(
                  label: 'Misery index',
                  value: miseryIndex.toStringAsFixed(1),
                ),
                Text(
                  'All negative values favor Republicans and all positive values favor Democrats (true values inverted as neccessary), misery index is the deviation from the historical mean.',
                ),
                IconButton(
                  tooltip: 'Meaning of ratings',
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('How to read the forecast'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'Tilt D/R: margin under 2 percentage points. Pretty much a tossup\nLean D/R: margin of 2-5 percentage points. A party is clearly favored but upsets happen quite often.\nLikely D/R: margin of 5-10 percentage points. A party is very strongly favored and will only rarely be upset.\nSafe D/R: 10+ percentage points. The state is most often pretty much a one-party state and the other party winning is unheard of.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest;
                      }
                      return Colors.transparent;
                    }),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  icon: Icon(Icons.info_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSignedPercent(double value) {
    final prefix = value >= 0 ? '+' : '-';
    return '$prefix${value.abs().toStringAsFixed(1)}%';
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
