import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp() will be wired in once flutterfire config has run.
  runApp(const ProviderScope(child: MoneySaverApp()));
}
