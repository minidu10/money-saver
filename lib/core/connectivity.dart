import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool isOnline(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);
  yield isOnline(await connectivity.checkConnectivity());
  await for (final results in connectivity.onConnectivityChanged) {
    yield isOnline(results);
  }
});
