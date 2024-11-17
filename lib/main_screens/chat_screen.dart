import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/widgets/bottom_chat_field.dart';
import 'package:flutter_chat_pro/widgets/chat_app_bar.dart';
import 'package:flutter_chat_pro/widgets/chat_list.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/message_model.dart';
import '../providers/authentication_provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    //get arguments pass from previous screen
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    //get the contactUID from arguments
    final contactUID = args[Constants.contactUID];
    final contactName = args[Constants.contactName];
    final contactImage = args[Constants.contactImage];
    final groupId = args[Constants.groupId];

    //check if the groupId is empty - then its a chat with a friend
    //else is a group chat
    final isGroupChat = groupId.isNotEmpty ? true : false;

    return Scaffold(
      appBar: AppBar(title: ChatAppBar(contactUID: contactUID)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
                child: chatList(
              contactUID: contactUID,
              groupId: groupId,
            )),
            BottomChatField(
                contactUID: contactUID,
                contactName: contactName,
                contactImage: contactImage,
                groupId: groupId)
          ],
        ),
      ),
    );
  }
}
