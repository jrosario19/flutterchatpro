import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/authentication_provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {

bool isDarkTheme = false;
  void getThemeMode() async {
    final savedThemeMode = await AdaptiveTheme.getThemeMode();
    if (savedThemeMode == AdaptiveThemeMode.dark) {
      setState(() {
        isDarkTheme = true;
      });
    } else {
      setState(() {
        isDarkTheme = false;
      });
    }
  }

  @override
  void initState() {
    getThemeMode();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    //get uid from arguments
    final uid = ModalRoute.of(context)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
        actions: [
          currentUser.uid==uid?
          IconButton(
            onPressed: () async{
              showDialog(context: context, builder: (context)=>AlertDialog(
                title: Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(onPressed: (){
                    Navigator.pop(context);
                  }, child: Text('Cancel')),
                  TextButton(onPressed: ()async{
                    await context.read<AuthenticationProvider>().logout().whenComplete(() {
                      Navigator.pushReplacementNamed(context, Constants.loginScreen);
                    });
                  }, child: Text('Logout'))
                ],
              ));
            },
            icon: Icon(Icons.logout),
          ):SizedBox.shrink()
        ],),
      body: Center(
        child: Card(
            child: SwitchListTile(
                value: isDarkTheme,
                title: Text('Change Theme'),
                secondary: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                  child: Icon(
                    isDarkTheme
                        ? Icons.nightlife_rounded
                        : Icons.wb_sunny_rounded,
                    color: isDarkTheme ? Colors.black : Colors.white,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    isDarkTheme = value;
                  });
                  if (value) {
                    AdaptiveTheme.of(context).setDark();
                  } else {
                    AdaptiveTheme.of(context).setLight();
                  }
                })),
      ),
    );
    ;
  }
}