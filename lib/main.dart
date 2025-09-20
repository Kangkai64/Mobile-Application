import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/active_jobs_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'utils/local_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:provider/provider.dart';
import 'providers/work_orders_provider.dart';
import 'providers/settings_provider.dart';
import 'services/supabase_service.dart';
import 'services/staff_service.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize the Supabase service with service role capabilities
  SupabaseService.instance.initializeServiceClient();

  await LocalStorage.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WorkOrdersProvider>(
          create: (_) => WorkOrdersProvider()..loadWorkOrders(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider()..load(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsProvider>();
          return MaterialApp(
            title: 'Greenstem Workshop Management',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            themeMode: settings.themeMode,
            home: const RootRouter(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  final _staffService = StaffService();
  bool _isLoading = true;
  bool _isValidStaff = false;

  @override
  void initState() {
    super.initState();
    _validateStaffUser();
    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      setState(() {});
      final session = event.session;
      if (session != null) {
        await LocalStorage.setString('user_email', session.user.email ?? '');
        _validateStaffUser();
      } else {
        await LocalStorage.remove('user_email');
        setState(() {
          _isValidStaff = false;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _validateStaffUser() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _isValidStaff = false;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if user is valid staff member
      final staff = await _staffService.fetchByEmail(session.user.email ?? '');
      if (staff != null && staff.authUserId == session.user.id) {
        setState(() {
          _isValidStaff = true;
          _isLoading = false;
        });
        return;
      }

      // If not a valid staff member, sign out
      await Supabase.instance.client.auth.signOut();
      setState(() {
        _isValidStaff = false;
        _isLoading = false;
      });
    } catch (e) {
      print('Error validating staff user: $e');
      setState(() {
        _isValidStaff = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || !_isValidStaff) {
      return const LoginScreen();
    }

    return const MainScreen();
  }
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DashboardScreen(),
      const ActiveJobsScreen(),
      const CameraScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Active Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}