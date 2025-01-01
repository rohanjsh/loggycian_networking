import 'dart:async';

import 'package:loggycian_networking/src/domain/domain.dart';

final class NetworkLoggingRepository {
  const NetworkLoggingRepository._();

  static Map<String, NetworkRequestDetailsModel> logs =
      <String, NetworkRequestDetailsModel>{};
  static StreamController<List<NetworkRequestDetailsModel>>
      logsStreamController =
      StreamController<List<NetworkRequestDetailsModel>>.broadcast();

  static void log({
    required String id,
    required NetworkRequestDetailsModel log,
  }) {
    logs[id] = log;
    logsStreamController.add(logs.values.toList());
  }

  static void clearSelectedLogs(List<NetworkRequestDetailsModel> networkLogs) {
    for (final log in networkLogs) {
      logs.removeWhere((_, value) => value == log);
    }
    logsStreamController.add(logs.values.toList());
  }

  static void clearAllLogs() {
    logs.clear();
    logsStreamController.add([]);
  }

  static void disposeListeners() {
    logsStreamController.close();
    logs.clear();
  }
}
