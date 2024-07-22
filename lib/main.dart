import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tour_guide/audience/audience_view.dart';
import 'package:tour_guide/common/common_controller.dart';
import 'package:tour_guide/env/env.dart';
import 'package:tour_guide/presenter/presenter_view.dart';
import 'package:tour_guide/utils/page_utils.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseApiKey);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Tour Guide Audio'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  void initState() {
    ref.read(commonCtrlProvider).initialize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please select the role play:'),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: const Text('Presenter'),
                  onPressed: () {
                    context.goto(page: PresenterView());
                  },
                ),
                ElevatedButton(
                  child: const Text('Audience'),
                  onPressed: () {
                    context.goto(page: AudienceView());
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
