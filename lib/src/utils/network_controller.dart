import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkController extends GetxController {
  final _isConnected = true.obs;

  bool get isConnected => _isConnected.value;

  @override
  void onInit() {
    super.onInit();
    Connectivity().onConnectivityChanged.listen((result) {
      _isConnected.value = result != ConnectivityResult.none;

      if (!_isConnected.value) {
        // Navigate to NoInternet screen
        Get.toNamed('/no-internet');
      } else {
        // Pop NoInternet screen if already in it
        if (Get.currentRoute == '/no-internet') {
          Get.back();
        }
      }
    });
  }
}