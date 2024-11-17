import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/main_screens/groups_screen.dart';
import 'package:flutter_chat_pro/main_screens/people_screen.dart';
import 'package:flutter_chat_pro/providers/authentication_provider.dart';
import 'package:flutter_chat_pro/utilities/global_methods.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../utilities/assets_manager.dart';
import 'my_chats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  int currentIndex = 0;
  final PageController pageController = PageController(initialPage: 0);
  final List<Widget> pages = [
    MyChatsScreen(),
    GroupsScreen(),
    PeopleScreen(),
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        context.read<AuthenticationProvider>().updateUserStatus(isOnline: true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        context
            .read<AuthenticationProvider>()
            .updateUserStatus(isOnline: false);
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthenticationProvider>();
    return Scaffold(
        appBar: AppBar(
          title: Text('Flutter Chat Pro'),
          actions: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: userImageWidget(
                    imageUrl: authProvider.userModel!.image,
                    radiis: 20,
                    onTap: () {
                      //navigate to profile screen with uid as argument
                      Navigator.pushNamed(
                        context,
                        Constants.profileScreen,
                        arguments: authProvider.userModel!.uid,
                      );
                    }))
          ],
        ),
        body: PageView(
            children: pages,
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            }),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chat_bubble_2),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.group),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.globe),
              label: 'People',
            ),
          ],
          currentIndex: currentIndex,
          onTap: (index) {
            pageController.animateToPage(index,
                duration: Duration(milliseconds: 300), curve: Curves.easeIn);
            setState(() {
              currentIndex = index;
            });
          },
        ));
  }
}
