import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_pro/models/message_reply_model.dart';
import 'package:flutter_chat_pro/widgets/contact_message_widget.dart';
import 'package:flutter_chat_pro/widgets/my_message_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:provider/provider.dart';

import '../models/message_model.dart';
import '../providers/authentication_provider.dart';
import '../providers/chat_provider.dart';
import '../utilities/global_methods.dart';

class chatList extends StatefulWidget {
  const chatList({super.key, required this.contactUID, required this.groupId});

  final String contactUID;
  final String groupId;

  @override
  State<chatList> createState() => _chatListState();
}

class _chatListState extends State<chatList> {
  //scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //current user uid
    final uid = context.read<AuthenticationProvider>().uid;
    return StreamBuilder<List<MessageModel>>(
        stream: context.read<ChatProvider>().getMessagesStream(
            userId: uid!,
            contactUID: widget.contactUID,
            isGroup: widget.groupId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.minScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          });
          if (snapshot.hasData) {
            final messages = snapshot.data!;
            return GroupedListView<dynamic, DateTime>(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              reverse: true,
              controller: _scrollController,
              elements: messages,
              groupBy: (element) {
                return DateTime(element.timeSent.year, element.timeSent.month,
                    element.timeSent.day);
              },
              groupHeaderBuilder: (dynamic groupedByValue) =>
                  SizedBox(height: 40, child: buildDateTime(groupedByValue)),
              itemBuilder: (context, dynamic element) {
                final dateTime =
                    formatDate(element.timeSent, [hh, ':', nn, ' ', am]);

                //set message as seen
                if (element.isSeen == false && element.senderUID != uid) {
                  context.read<ChatProvider>().setMessageAsSeen(
                      userId: uid,
                      contactUID: widget.contactUID,
                      messageId: element.messageId,
                      groupId: widget.groupId);
                }

                final isMe = element.senderUID == uid;
                return isMe
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Padding(
                            padding:
                                const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: MyMessageWidget(
                                message: element,
                                onRightSwipe: () {
                                  //set the message reply
                                  final messageReply = MessageReplyModel(
                                      message: element.message,
                                      senderUID: element.senderUID,
                                      senderName: element.senderName,
                                      senderImage: element.senderImage,
                                      messageType: element.messageType,
                                      isMe: isMe);
                                  context
                                      .read<ChatProvider>()
                                      .setMessageReplyModel(messageReply);
                                })),
                      )
                    : ContactMesageWidget(
                        message: element,
                        onRightSwipe: () {
                          //set the message reply
                          final messageReply = MessageReplyModel(
                              message: element.message,
                              senderUID: element.senderUID,
                              senderName: element.senderName,
                              senderImage: element.senderImage,
                              messageType: element.messageType,
                              isMe: isMe);
                          context
                              .read<ChatProvider>()
                              .setMessageReplyModel(messageReply);
                        });
              },
              groupComparator: ((value1, value2) => value2.compareTo(value1)),
              itemComparator: (item1, item2) {
                var firstItem = item1.timeSent;
                var secondItem = item2.timeSent;
                return secondItem.compareTo(firstItem);
              },

              /// optional
              useStickyGroupSeparators: true, // optional
              floatingHeader: true, // optional
              order: GroupedListOrder.ASC, // optional
              /* footer:
                              Text("Widget at the bottom of list"), */ // optional
            );
          }
          return Center(
            child: Text(
              'Start a conversation',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),
          );
        });
  }
}
