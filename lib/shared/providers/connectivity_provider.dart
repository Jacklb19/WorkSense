import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (results) =>
        results.isNotEmpty &&
        results.any((r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Single ConnectivityResult (first result from list)
final connectivityResultProvider = Provider<ConnectivityResult>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (results) =>
        results.isNotEmpty ? results.first : ConnectivityResult.none,
    loading: () => ConnectivityResult.none,
    error: (_, __) => ConnectivityResult.none,
  );
});
