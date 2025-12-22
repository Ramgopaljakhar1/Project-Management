import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';


enum NetworkStatus { Online, Offline }

class NetworkStatusService {
  StreamController<NetworkStatus> networkStatusController =
  StreamController<NetworkStatus>();

  // NetworkStatusService() {
  //   Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
  //     _networkStatusController.add(_getNetworkStatus(result));
  //   });
  // }

  NetworkStatusService() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> statusList) {
      for (var status in statusList) {
        networkStatusController.add(_getNetworkStatus(status));
      }
    });
  }
  Stream<NetworkStatus> get networkStatusStream => networkStatusController.stream;

  NetworkStatus _getNetworkStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
      return NetworkStatus.Online;
    } else {
      return NetworkStatus.Offline;
    }
  }

  void dispose() {
    networkStatusController.close();
  }
}