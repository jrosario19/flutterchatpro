import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/constants.dart';
import 'package:flutter_chat_pro/models/last_message_model.dart';
import 'package:flutter_chat_pro/providers/authentication_provider.dart';
import 'package:flutter_chat_pro/providers/chat_provider.dart';
import 'package:flutter_chat_pro/utilities/global_methods.dart';
import 'package:provider/provider.dart';
import 'package:date_format/date_format.dart';

class MyChatsScreen extends StatefulWidget {
  const MyChatsScreen({super.key});

  @override
  State<MyChatsScreen> createState() => _MyChatsScreenState();
}

class _MyChatsScreenState extends State<MyChatsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().uid;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
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
                child: StreamBuilder<List<LastMessageModel>>(
                    stream: context
                        .read<ChatProvider>()
                        .getChatListStream(userId: uid!),
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
                      if (snapshot.hasData) {
                        final chatList = snapshot.data!;

                        return ListView.builder(
                          itemCount: chatList.length,
                          itemBuilder: (context, index) {
                            final chat = chatList[index];
                            final dateTime = formatDate(
                                chat.timeSent, [hh, ':', mm, ' ', am]);
                            //check if we sent the last message
                            final isMe = chat.senderUID == uid;
                            final lastMessage =
                                isMe ? 'You: ${chat.message}' : chat.message;
                            return ListTile(
                              leading: userImageWidget(
                                  imageUrl: chat.contactImage,
                                  radiis: 40,
                                  onTap: () {}),
                              contentPadding: EdgeInsets.zero,
                              title: Text(chat.contactName),
                              subtitle: Text(
                                lastMessage,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(dateTime),
                              onTap: () {
                                Navigator.pushNamed(
                                    context, Constants.chatScreen,
                                    arguments: {
                                      Constants.contactUID: chat.contactUID,
                                      Constants.contactName: chat.contactName,
                                      Constants.contactImage: chat.contactImage,
                                      Constants.groupId: '',
                                    });
                              },
                            );
                          },
                        );
                      }
                      return const Center(
                        child: Text('No chats yet'),
                      );
                    })),
          ],
        ),
      ),
    );
  }
}
