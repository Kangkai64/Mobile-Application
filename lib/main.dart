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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://dzajfltnnwjaoalaimob.supabase.co',
    anonKey: 'sb_secret_V-wmePWdJH9SggsJXDvZxg_d-rttjIG',
  );
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
    return ChangeNotifierProvider<WorkOrdersProvider>(
      create: (_) => WorkOrdersProvider()..loadWorkOrders(),
      child: MaterialApp(
        title: 'Greenstem Workshop Management',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const RootRouter(),
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
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      setState(() {});
      final session = event.session;
      if (session != null) {
        await LocalStorage.setString('user_email', session.user.email ?? '');
      } else {
        await LocalStorage.remove('user_email');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const LoginScreen();
    }
    return const MainScreen();
  }
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {

    final List<Widget> _screens = [
      const DashboardScreen(),
      const ActiveJobsScreen(),
      const CameraScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: _screens[_currentIndex],
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
