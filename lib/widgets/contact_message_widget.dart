import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/models/message_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipe_to/swipe_to.dart';

import '../constants.dart';
import 'display_massage_type.dart';

class ContactMesageWidget extends StatelessWidget {
  const ContactMesageWidget(
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
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                minWidth: MediaQuery.of(context).size.width * 0.3,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Stack(
                    children: [
                      Padding(
                        padding: message.messageType == MessageEnum.text
                            ? const EdgeInsets.fromLTRB(10.0, 5.0, 20.0, 20.0)
                            : const EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isReplying) ...[
                              Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.repliedTo,
                                          style: GoogleFonts.openSans(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black),
                                        ),
                                        DisplayMessageType(
                                          message: message.repliedMessage,
                                          messageType: message.messageType,
                                          color: Colors.black,
                                          maxLines: 1,
                                          overFlow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ))
                            ],
                            DisplayMessageType(
                                message: message.message,
                                messageType: message.messageType,
                                color: Colors.black),
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
                                style: TextStyle(
                                    fontSize: 10, color: Colors.black),
                              ),
                            ],
                          ))
                    ],
                  ),
                ),
              ))),
    );
  }
}
