import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'inference.dart';

part 'logic.dart';

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

  @override
  void initState() {
    super.initState();
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
              );
            }

            final forecast = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                  Text(
                    'State forecasts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisExtent: 190,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: forecast.states.length,
                      itemBuilder: (context, index) {
                        final state = forecast.states[index];
                        final pollingWeight = _pollingWeight();
                        final displayedForecast = _stateForecastValue(
                          state,
                          pollingWeight,
                        );
                        final accentColor = _stateCardColor(displayedForecast);

                        return Card(
                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1.5),
                            borderRadius: BorderRadius.circular(18),
                          ),
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
                                            _formatSignedPercent(
                                              displayedForecast,
                                            ),
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  color: accentColor,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          Text(
                                            forecastCatergory(
                                              displayedForecast,
                                            ),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: accentColor,
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
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.pollingAverage != null
                                      ? state.pollingAverage!.toStringAsFixed(1)
                                      : 'Unavailable',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '2022 PVI',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatSignedPercent(state.pvi2022),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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

  double _stateForecastValue(StateForecast state, double pollingWeight) {
    if (state.pollingAverage == null) {
      return state.forecast;
    }

    return (state.forecast * (1 - pollingWeight)) +
        (state.pollingAverage! * pollingWeight);
  }

  // TODO: Add different colors for Tilt/Lean/Likely/Safe D/R

  Color _stateCardColor(double forecast) {
    if (forecast > 0) {
      return const Color.fromARGB(255, 25, 0, 255);
    }

    if (forecast < 0) {
      return const Color.fromARGB(255, 255, 0, 0);
    }

    return const Color(0xFF4B5563);
  }

  String _formatSignedPercent(double value) {
    final suffix = value >= 0 ? '+' : '-';
    final absoluteValue = value.abs();
    final formatted = absoluteValue.toStringAsFixed(1);
    return '$suffix$formatted%';
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Bundled data',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
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
            const SizedBox(height: 6),
            Text(
              _forecastCategory(nationalLean),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _forecastCategory(double forecast) {
    final abs = forecast.abs();
    final party = forecast >= 0 ? 'D' : 'R';

    if (abs < 2) {
      return 'Tilt $party';
    }

    if (abs < 5) {
      return 'Lean $party';
    }

    if (abs < 10) {
      return 'Likely $party';
    }

    return 'Safe $party';
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
