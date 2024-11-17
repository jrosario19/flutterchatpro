import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/constants.dart';

import '../widgets/app_bar_back_button.dart';
import '../widgets/friends_list.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(onPressed: () {
          Navigator.pop(context);
        }),
        centerTitle: true,
        title: Text('Friend Requests Screen'),
      ),
      body: Column(
        children: [
          //cupertino search textfield
          CupertinoSearchTextField(
            placeholder: 'Search',
            style: TextStyle(
              color: Colors.white,
            ),
            onChanged: (value) {
              print(value);
            },
          ),
          Expanded(
              child: FriendsLIst(
            viewTpe: FriendViewType.friendRequests,
          )),
        ],
      ),
    );
  }
}
