import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/constants.dart';
import 'package:flutter_chat_pro/models/message_model.dart';
import 'package:flutter_chat_pro/widgets/display_massage_type.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipe_to/swipe_to.dart';

class MyMessageWidget extends StatelessWidget {
  const MyMessageWidget(
      {super.key, required this.message, required this.onRightSwipe});

  final MessageModel message;
  final Function() onRightSwipe;

  @override
  Widget build(BuildContext context) {
    final time = formatDate(message.timeSent, [hh, ':', nn, ' ', am]);
    final isReplying = message.repliedTo.isNotEmpty;
    return SwipeTo(
      onRightSwipe: (details) {
        onRightSwipe();
      },
      child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
                minWidth: MediaQuery.of(context).size.width * 0.3,
              ),
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(10.0)),
                child: Stack(
                  children: [
                    Padding(
                      padding: message.messageType == MessageEnum.text
                          ? const EdgeInsets.fromLTRB(10.0, 5.0, 20.0, 20.0)
                          : const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isReplying) ...[
                            Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColorDark
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        message.repliedTo,
                                        style: GoogleFonts.openSans(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      DisplayMessageType(
                                        message: message.repliedMessage,
                                        messageType: message.messageType,
                                        color: Colors.white,
                                        maxLines: 1,
                                        overFlow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                          DisplayMessageType(
                              message: message.message,
                              messageType: message.messageType,
                              color: Colors.white),
                        ],
                      ),
                    ),
                    Positioned(
                        bottom: 4,
                        right: 10,
                        child: Row(
                          children: [
                            Text(
                              time,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.openSans(
                                  fontSize: 10, color: Colors.white),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Icon(
                              message.isSeen ? Icons.done_all : Icons.done,
                              color:
                                  message.isSeen ? Colors.blue : Colors.white60,
                              size: 15,
                            )
                          ],
                        ))
                  ],
                ),
              ))),
    );
  }
}
