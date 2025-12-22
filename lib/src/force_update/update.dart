import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_management/src/utils/colors.dart';
import 'package:project_management/src/utils/img.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common_widgets/app_state_screen.dart';


class Update extends StatefulWidget {


  @override
  UpdateState createState() =>  UpdateState();
}



class  UpdateState extends State<Update> {
  @override
  void initState() {
    super.initState();
  }
  // final String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.mpcb.surveyor&hl=en'; // 🔁 Replace with your app's package name

  final String androidAppId = 'com.app.projectmanagement';
  final String iOSAppId = '6747034838'; // e.g. 'id1234567890'

  void _launchStore() async {
    Uri url;

    if (Platform.isAndroid) {
      url = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.app.projectmanagement');
    } else if (Platform.isIOS) {
      url = Uri.parse('https://apps.apple.com/app/$iOSAppId');
      print(url);
    } else {
      return;
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('⚠️ Could not launch $url');
    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: AppStateScreen(
          topSpacing: 40,
          bottomSpacing: 40,
          showAppBar: true,
          showBackArrow: false,
          imagePath: AppImages.forceAppUpdate,
          title: 'We’re better than ever',
          subtitle1: 'For more features and a better user',
          subtitle2: 'Experience, please update this APP.',
          buttonText: 'Update App',
          onButtonPressed: () => {_launchStore()},
        ));




  }
}