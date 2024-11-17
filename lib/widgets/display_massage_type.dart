import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_pro/constants.dart';

class DisplayMessageType extends StatelessWidget {
  const DisplayMessageType(
      {super.key,
      required this.message,
      required this.messageType,
      required this.color,
      this.maxLines,
      this.overFlow});
  final String message;
  final MessageEnum messageType;
  final Color color;
  final int? maxLines;
  final TextOverflow? overFlow;

  @override
  Widget build(BuildContext context) {
    Widget messageToShow() {
      switch (messageType) {
        case MessageEnum.text:
          return Text(message,
              style: TextStyle(color: color),
              maxLines: maxLines,
              overflow: overFlow);
        case MessageEnum.image:
          return CachedNetworkImage(imageUrl: message, fit: BoxFit.cover);
        case MessageEnum.audio:
          return Text(message,
              style: TextStyle(color: color),
              maxLines: maxLines,
              overflow: overFlow);
        case MessageEnum.video:
          return Image.network(message, fit: BoxFit.cover);
        default:
          return Text(message,
              style: TextStyle(color: color),
              maxLines: maxLines,
              overflow: overFlow);
      }
    }

    return messageToShow();
  }
}
