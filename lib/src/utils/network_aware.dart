import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'network_status.dart';

class NetworkAwareWidget extends StatelessWidget {
  final Widget onlineChild;
  final Widget offlineChild;

  const NetworkAwareWidget({
    Key? key,
    required this.onlineChild,
    required this.offlineChild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkStatus>(
      stream: Provider.of<NetworkStatusService>(context).networkStatusStream,
      builder: (context, snapshot) {
        // Check for the stream's connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());  // Show loading while checking network status
        }

        // Check if we have a valid data response from the stream
        if (snapshot.hasData) {
          if (snapshot.data == NetworkStatus.Online) {
            return onlineChild; // Show online content if connected
          } else {
            return offlineChild; // Show offline content if not connected
          }
        }

        // Handle cases where the snapshot doesn't have any data (e.g., network error)
        return offlineChild; // Fallback to offline child if there's no data
      },
    );
  }

  // Example method to show a toast message (if you want to notify the user of the network status change)
  void _showToastMessage(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
