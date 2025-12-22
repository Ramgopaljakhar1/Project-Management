import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  save(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    final str = json.encode(value);
    debugPrint("save str = $str");
    prefs.setString(key, str);

    debugPrint("saved val = $str");

  }

  read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final strRes = prefs.getString(key);
    //debugPrint("read strRes = ${strRes}");
    if (strRes != null) {
      final jsonRes = json.decode(strRes);
      //debugPrint("read json = ${jsonRes}");
      return jsonRes;
    }
  }
  saveUserData(String key, value) async {
    final pref = await SharedPreferences.getInstance();
    pref.setString(key, jsonEncode(value));
    debugPrint("UserData: $value");
  }


  clearSaveData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }


  Future<void> write(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(value);
    prefs.setString(key, jsonString);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  readUserData(String kUserData) {

  }

  Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final result = await prefs.remove(key);
    debugPrint("🗑️ Removed key: $key");
    return result; // ✅ Return the result
  }


}