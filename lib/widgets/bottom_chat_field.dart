import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/constants.dart';
import 'package:flutter_chat_pro/providers/chat_provider.dart';
import 'package:flutter_chat_pro/utilities/global_methods.dart';
import 'package:flutter_chat_pro/widgets/message_reply_preview.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/authentication_provider.dart';

class BottomChatField extends StatefulWidget {
  const BottomChatField(
      {super.key,
      required this.contactUID,
      required this.contactName,
      required this.contactImage,
      required this.groupId});

  final String contactUID;
  final String contactName;
  final String contactImage;
  final String groupId;
  @override
  State<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends State<BottomChatField> {
  late TextEditingController _messageController;
  late FocusNode _messageFocus;
  File? finalFileImage;
  String filePath = '';

  @override
  void initState() {
    _messageController = TextEditingController();
    _messageFocus = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void selectImage(bool fromCamera) async {
    finalFileImage = await pickImage(
        fromCamera: fromCamera,
        onFail: (error) {
          showSnackBar(context, error);
        });
    //crop image
    if (finalFileImage != null) {
      cropImage(finalFileImage!.path);
    }
  }

  void cropImage(String croppedFilePath) async {
    if (croppedFilePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: croppedFilePath,
          maxHeight: 800,
          maxWidth: 800,
          compressQuality: 90);
      //popTheDialog();
      if (croppedFile != null) {
        filePath = croppedFile.path;
        //send image message to firestore
        sendFileMessage(messageType: MessageEnum.image);
      } else {
        //popTheDialog();
      }
    }
  }

  //send image message to firestore
  void sendFileMessage({required MessageEnum messageType}) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendFileMessage(
        sender: currentUser,
        contactUID: widget.contactUID,
        contactName: widget.contactName,
        contactImage: widget.contactImage,
        file: File(filePath),
        messageType: messageType,
        groupId: widget.groupId,
        onSuccess: () {
          _messageController.clear();
          _messageFocus.requestFocus();
        },
        onError: (error) {
          showSnackBar(context, error);
        });
  }

    //send text message to firestore
    void sendTextMessage() {
      final currentUser = context.read<AuthenticationProvider>().userModel!;
      final chatProvider = context.read<ChatProvider>();

      chatProvider.sendTextMessage(
          sender: currentUser,
          contactUID: widget.contactUID,
          contactName: widget.contactName,
          contactImage: widget.contactImage,
          message: _messageController.text,
          messageType: MessageEnum.text,
          groupId: widget.groupId,
          onSuccess: () {
            _messageController.clear();
            _messageFocus.requestFocus();
          },
          onError: (error) {
            showSnackBar(context, error);
          });
    }


    @override
    Widget build(BuildContext context) {
      return Consumer<ChatProvider>(builder: (context, chatProvider, child) {
        final messageReplyModel = chatProvider.messageReplyModel;
        final isMessageReply = messageReplyModel != null;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: Column(
            children: [
              isMessageReply ? MessageReplyPreview() : SizedBox.shrink(),
              Row(
                children: [
                  chatProvider.isLoading?CircularProgressIndicator():
                  IconButton(
                      onPressed: () {
                        showBottomSheet(
                            context: context,
                            builder: (context) {
                              return SizedBox(
                                height: 200,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      //select image from camera
                                      ListTile(
                                        leading: Icon(Icons.camera_alt),
                                        title: Text("Camera"),
                                        onTap: () {
                                          selectImage(true);
                                          Navigator.pop(context);
                                        },
                                      ),
                                      //select image from gallery
                                      ListTile(
                                          leading: Icon(Icons.image),
                                          title: Text("Gallery"),
                                          onTap: () {
                                            selectImage(false);
                                            Navigator.pop(context);
                                          }),
                                          //select a video file from device
                                          ListTile(
                                          leading: Icon(Icons.video_library),
                                          title: Text("Video"),
                                          onTap: () {
                                          })
                                    ],
                                  ),
                                ),
                              );
                            });
                      },
                      icon: Icon(Icons.attachment)),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocus,
                      decoration: InputDecoration.collapsed(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        hintText: "Type a message",
                      ),
                    ),
                  ),
                  chatProvider.isLoading
                    ? CircularProgressIndicator()
                    : GestureDetector(
                    onTap: sendTextMessage,
                    child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.deepPurple,
                        ),
                        margin: EdgeInsets.all(5),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                          ),
                        )),
                  ),
                ],
              ),
            ],
          ),
        );
      });
    }
  
}
