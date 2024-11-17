import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/providers/chat_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MessageReplyPreview extends StatelessWidget {
  const MessageReplyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messageReplyModel = chatProvider.messageReplyModel;
        final isMe = messageReplyModel!.isMe;
        return Container(
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30))),
            child: ListTile(
              title: Text(
                isMe ? 'You' : messageReplyModel.senderName,
                style: GoogleFonts.openSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              subtitle: Text(
                messageReplyModel.message,
                style: GoogleFonts.openSans(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              trailing: IconButton(
                  onPressed: () {
                    chatProvider.setMessageReplyModel(null);
                  },
                  icon: Icon(
                    Icons.close,
                  )),
            ));
      },
    );
  }
}
