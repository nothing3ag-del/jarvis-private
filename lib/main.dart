import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/jarvis_controller.dart';
import 'ui/hologram_jarvis_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: JarvisProApp()));
}

class JarvisProApp extends StatelessWidget {
  const JarvisProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030712),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF),
          secondary: Color(0xFF0077FF),
        ),
      ),
      home: const JarvisHomeScreen(),
    );
  }
}

class JarvisHomeScreen extends ConsumerStatefulWidget {
  const JarvisHomeScreen({super.key});

  @override
  ConsumerState<JarvisHomeScreen> createState() => _JarvisHomeScreenState();
}

class _JarvisHomeScreenState extends ConsumerState<JarvisHomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(jarvisProvider.notifier).initializeSystem());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(jarvisProvider.notifier);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      notifier.setRenderActive(false);
    } else if (state == AppLifecycleState.resumed) {
      notifier.setRenderActive(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: HologramJarvisView(),
    );
  }
}
