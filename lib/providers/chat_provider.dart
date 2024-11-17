import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_pro/constants.dart';
import 'package:flutter_chat_pro/models/last_message_model.dart';
import 'package:flutter_chat_pro/models/message_model.dart';
import 'package:flutter_chat_pro/models/message_reply_model.dart';
import 'package:flutter_chat_pro/models/user_model.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  bool _isLoading = false;
  MessageReplyModel? _messageReplyModel;

  bool get isLoading => _isLoading;
  MessageReplyModel? get messageReplyModel => _messageReplyModel;

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setMessageReplyModel(MessageReplyModel? messageReplyModel) {
    _messageReplyModel = messageReplyModel;
    notifyListeners();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  //send text message to firestore
  void sendTextMessage(
      {required UserModel sender,
      required String contactUID,
      required String contactName,
      required String contactImage,
      required String message,
      required MessageEnum messageType,
      required String groupId,
      required Function onSuccess,
      required Function(String) onError}) async {
    //set isLoading to true
    setIsLoading(true);
    notifyListeners();
    try {
      var messageId = const Uuid().v1();
      //1. check if it is a message or a reply and add the replied message to the message
      String repliedMessage = _messageReplyModel?.message ?? '';
      String repliedTo = _messageReplyModel == null
          ? ''
          : _messageReplyModel!.isMe
              ? 'You'
              : _messageReplyModel!.senderName;
      MessageEnum repliedMessageType =
          _messageReplyModel?.messageType ?? MessageEnum.text;

      //2. update/set the message model class
      final messageModel = MessageModel(
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: contactUID,
        message: message,
        messageType: messageType,
        timeSent: DateTime.now(),
        messageId: messageId,
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        reactions: [],
        isSeenBy: [],
        deletedBy: [],
      );

      //3. check if it is a group message and send to the group else send to the contact
      if (groupId.isNotEmpty) {
        //handle group message
      } else {
        //handle contact message
        await handleContactMessage(
          messageModel: messageModel,
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          onSuccess: onSuccess,
          onError: onError,
        );

        //set message reply model to null
        setMessageReplyModel(null);
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  //send file message to firestore
  Future<void> sendFileMessage(
      {required UserModel sender,
      required String contactUID,
      required String contactName,
      required String contactImage,
      required File file,
      required MessageEnum messageType,
      required String groupId,
      required Function onSuccess,
      required Function(String) onError}) async {
    //set isLoading to true
    setIsLoading(true);
    notifyListeners();
    try {
      var messageId = const Uuid().v4();
      //1. check if it is a message or a reply and add the replied message to the message
      String repliedMessage = _messageReplyModel?.message ?? '';
      String repliedTo = _messageReplyModel == null
          ? ''
          : _messageReplyModel!.isMe
              ? 'You'
              : _messageReplyModel!.senderName;
      MessageEnum repliedMessageType =
          _messageReplyModel?.messageType ?? MessageEnum.text;
      //2. upload file to firebase storage
      final ref =
          ('${Constants.chatFiles}/${messageType.name}/${sender.uid}/$contactUID/$messageId');
      String fileURL =
          await uploadFileToFirebaseStorage(file: file, reference: ref);
      //2. update/set the message model class
      final messageModel = MessageModel(
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: contactUID,
        message: fileURL,
        messageType: messageType,
        timeSent: DateTime.now(),
        messageId: messageId,
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        reactions: [],
        isSeenBy: [],
        deletedBy: [],
      );

      //3. check if it is a group message and send to the group else send to the contact
      if (groupId.isNotEmpty) {
        //handle group message
      } else {
        //handle contact message
        await handleContactMessage(
          messageModel: messageModel,
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          onSuccess: onSuccess,
          onError: onError,
        );
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> handleContactMessage(
      {required MessageModel messageModel,
      required String contactUID,
      required String contactName,
      required String contactImage,
      required Function onSuccess,
      required Function(String p1) onError}) async {
    try {
      //0. contact message model
      final contactMessageModel = messageModel.copyWith(
        userId: messageModel.senderUID,
      );

      //1. initialize last message for the sender
      final senderLastMessage = LastMessageModel(
          senderUID: messageModel.senderUID,
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          message: messageModel.message,
          messageType: messageModel.messageType,
          timeSent: messageModel.timeSent,
          isSeen: false);
      //2. initialize last message for the contact
      final contactLastMessage = senderLastMessage.copyWith(
        contactUID: messageModel.senderUID,
        contactName: messageModel.senderName,
        contactImage: messageModel.senderImage,
      );

      //3. send message to serder firestore location
      await _firestore
          .collection(Constants.users)
          .doc(messageModel.senderUID)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .doc(messageModel.messageId)
          .set(messageModel.toMap());

      //4. send message to contact firestore location
      await _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .collection(Constants.chats)
          .doc(messageModel.senderUID)
          .collection(Constants.messages)
          .doc(messageModel.messageId)
          .set(contactMessageModel.toMap());

      //5. send the last message to sender firestore location
      await _firestore
          .collection(Constants.users)
          .doc(messageModel.senderUID)
          .collection(Constants.chats)
          .doc(contactUID)
          .set(senderLastMessage.toMap());

      //6. send the last message to contact firestore location
      await _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .collection(Constants.chats)
          .doc(messageModel.senderUID)
          .set(contactLastMessage.toMap());

      /* await _firestore.runTransaction((transaction) async {
        //3. send message to serder firestore location
        transaction.set(
          _firestore
              .collection(Constants.users)
              .doc(messageModel.senderUID)
              .collection(Constants.chats)
              .doc(contactUID)
              .collection(Constants.messages)
              .doc(messageModel.messageId),
          messageModel.toMap(),
        );

        //4. send message to contact firestore location
        transaction.set(
          _firestore
              .collection(Constants.users)
              .doc(contactUID)
              .collection(Constants.chats)
              .doc(messageModel.senderUID)
              .collection(Constants.messages)
              .doc(messageModel.messageId),
          contactMessageModel.toMap(),
        );
        
        transaction.set(
          _firestore
              .collection(Constants.users)
              .doc(messageModel.senderUID)
              .collection(Constants.chats)
              .doc(contactUID),
          senderLastMessage.toMap(),
        );

        //6. send the last message to contact firestore location
        transaction.set(
            _firestore
                .collection(Constants.users)
                .doc(contactUID)
                .collection(Constants.chats)
                .doc(messageModel.senderUID),
            contactLastMessage.toMap());
      }); */

      //7. call onSuccess
      setIsLoading(false);
      onSuccess();
    } on FirebaseException catch (e) {
      onError(e.toString());
    }
  }

  //set message as seen
  Future<void> setMessageAsSeen(
      {required String userId,
      required String contactUID,
      required String messageId,
      required String groupId}) async {
    try {
      if (groupId.isNotEmpty) {
        //handle group message
      } else {
        //handle contact message
        //2. update the current message as seen
        await _firestore
            .collection(Constants.users)
            .doc(userId)
            .collection(Constants.chats)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageId)
            .update({Constants.isSeen: true});

        //3. update the contact message as seen
        await _firestore
            .collection(Constants.users)
            .doc(contactUID)
            .collection(Constants.chats)
            .doc(userId)
            .collection(Constants.messages)
            .doc(messageId)
            .update({Constants.isSeen: true});

        //4. update the last message as seen
        await _firestore
            .collection(Constants.users)
            .doc(userId)
            .collection(Constants.chats)
            .doc(contactUID)
            .update({Constants.isSeen: true});

        //5. update the contact last message as seen
        await _firestore
            .collection(Constants.users)
            .doc(contactUID)
            .collection(Constants.chats)
            .doc(userId)
            .update({Constants.isSeen: true});
      }
    } on FirebaseException catch (e) {
      print(e.message);
    }
  }

  //get chat stream
  Stream<List<LastMessageModel>> getChatListStream({required String userId}) {
    return _firestore
        .collection(Constants.users)
        .doc(userId)
        .collection(Constants.chats)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((e) {
        return LastMessageModel.fromMap(e.data());
      }).toList();
    });
  }

  //stream messages from chat collection
  Stream<List<MessageModel>> getMessagesStream(
      {required String userId,
      required String contactUID,
      required String isGroup}) {
    //check if it is a group message
    if (isGroup.isNotEmpty) {
      return _firestore
          .collection(Constants.groups)
          .doc(contactUID)
          .collection(Constants.messages)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((e) {
          return MessageModel.fromMap(e.data());
        }).toList();
      });
    } else {
      return _firestore
          .collection(Constants.users)
          .doc(userId)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((e) {
          return MessageModel.fromMap(e.data());
        }).toList();
      });
    }
  }

  //upload file to firebase storage and return file url
  Future<String> uploadFileToFirebaseStorage(
      {required File file, required String reference}) async {
    UploadTask uploadTask =
        _firebaseStorage.ref().child(reference).putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}
