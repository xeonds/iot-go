import 'package:app/session_model.dart';
import 'package:app/settings.dart';
import 'package:app/automation_page.dart';
import 'package:app/device_list_page.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ChangeNotifierProvider(
    create: (context) => SessionModel(prefs),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT-Go',
      debugShowCheckedModeBanner: false,
      theme: FlexThemeData.light(
        scheme: FlexScheme.greenM3,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.greenM3,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
      ),
      // theme: ThemeData(
      //     colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
      //     useMaterial3: true),
      // darkTheme: ThemeData(
      //     colorScheme: ColorScheme.fromSeed(
      //         seedColor: Colors.lightGreen, brightness: Brightness.dark),
      //     useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const DeviceListPage(),
    const AutomationPage(),
    const AboutPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.inversePrimary,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Automation'),
          NavigationDestination(
              icon: Icon(Icons.settings),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: _onItemTapped,
      ),
    );
  }
}
