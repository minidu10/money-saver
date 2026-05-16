import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/notifications.dart';
import 'core/preferences.dart';
import 'data/local_cache.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Explicit offline cache: keep everything locally, unlimited size, so
  // the app keeps working without network and writes queue until reconnect.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final prefs = await SharedPreferences.getInstance();
  final notifications = await NotificationService.init();
  final txCache = await LocalTransactionsCache.init();
  // Required before GoogleSignIn.instance.authenticate(); reads
  // config from android/app/google-services.json automatically.
  await GoogleSignIn.instance.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
        localTransactionsCacheProvider.overrideWithValue(txCache),
      ],
      child: const MoneySaverApp(),
    ),
  );
}
