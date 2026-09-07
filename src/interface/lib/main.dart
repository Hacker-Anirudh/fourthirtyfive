import 'package:flutter/material.dart';

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
        brightness: isDark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
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
  static const List<String> usStates = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        leading: IconButton(onPressed: {} {
          showAboutDialog(context: context)
        }, icon: icon),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 120,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: usStates.length,
          itemBuilder: (context, index) {
            final state = usStates[index];

            return Card(
              color: Color.fromARGB(255, 128, 0, 0),
              child: Center(
                child: Text(
                  state,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onThemeToggle,
        child: Icon(
          widget.isDark ? Icons.brightness_2_outlined : Icons.wb_sunny_outlined,
        ),
      ),
    );
  }
}
