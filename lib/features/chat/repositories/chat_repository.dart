import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_ui/common/enum/message_enum.dart';
import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';

import 'package:whatsapp_ui/models/chat_contacts.dart';
import 'package:whatsapp_ui/models/message.dart';
import 'package:whatsapp_ui/models/user_model.dart';

final chatRepositoryProvider = Provider(
  ((ref) => ChatRepository(
      firestore: FirebaseFirestore.instance, auth: FirebaseAuth.instance)),
);

class ChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  ChatRepository({
    required this.firestore,
    required this.auth,
  });

  Stream<List<ChatContact>> getChatContacts() {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      List<ChatContact> contacts = [];
      for (var document in event.docs) {
        var chatContact = ChatContact.fromMap(document.data());
        // log(chatContact.toMap().toString());
        var userData = await firestore
            .collection('users')
            .doc(chatContact.contactId)
            .get();
        var user = UserModel.fromMap(userData.data()!);
        contacts.add(
          ChatContact(
              name: user.name,
              profilePic: user.profilePic,
              contactId: chatContact.contactId,
              timeSent: chatContact.timeSent,
              lastMessage: chatContact.lastMessage),
        );
      }
      return contacts;
    });
  }

  Stream<List<Message>> getChatStream(String receiverUserId) {
    return firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverUserId)
        .collection('messages')
        .orderBy('timeSent')
        .snapshots()
        .map((event) {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  void _saveDataToContactsSubCollection(
    UserModel sendUserData,
    UserModel receiverUserData,
    String text,
    DateTime timeSent,
    String receiverUserId,
  ) async {
    //users --> receivers user id --> chats-->currentuserId -->set data
    var receiverChatContact = ChatContact(
      name: sendUserData.name,
      profilePic: sendUserData.profilePic,
      contactId: sendUserData.uid,
      timeSent: timeSent,
      lastMessage: text,
    );
    await firestore
        .collection('users')
        .doc(receiverUserId)
        .collection('chats')
        .doc(auth.currentUser!.uid)
        .set(
          receiverChatContact.toMap(),
        );
    //users --> current user id --> chats-->receiver userId -->set data
    var senderChatContact = ChatContact(
      name: receiverUserData.name,
      profilePic: receiverUserData.profilePic,
      contactId: receiverUserData.uid,
      timeSent: timeSent,
      lastMessage: text,
    );
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverUserId)
        .set(
          senderChatContact.toMap(),
        );
  }

  void _saveMessageToMessageSubCollection(
      {required String receiverUserId,
      required String text,
      required DateTime timesent,
      required String messageId,
      required String username,
      required recieverUsername,
      required MessageEnum messageType}) async {
    final message = Message(
        senderId: auth.currentUser!.uid,
        receiverId: receiverUserId,
        text: text,
        type: messageType,
        timeSent: timesent,
        messageId: messageId,
        isSeen: false);

    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .collection('chats')
        .doc(receiverUserId)
        .collection('messages')
        .doc(messageId)
        .set(
          message.toMap(),
        );
    //user -------------------->recever id --> senderid --> messsaged---messaeid
    await firestore
        .collection('users')
        .doc(receiverUserId)
        .collection('chats')
        .doc(auth.currentUser!.uid)
        .collection('messages')
        .doc(messageId)
        .set(
          message.toMap(),
        );
  }

  void sendTextMessage({
    required BuildContext context,
    required String text,
    required String receiverUserId,
    required UserModel senderUser,
  }) async {
    // users-->sender-id---->receiver id --->messages-->message Id-->store message,
    try {
      var timeSent = DateTime.now();
      UserModel receiverUserData;

      var userDataMap =
          await firestore.collection('users').doc(receiverUserId).get();
      receiverUserData = UserModel.fromMap(userDataMap.data()!);
// users ->receiver user id -> currentuserid-->set data

      var messageId = const Uuid().v1();

      _saveDataToContactsSubCollection(
          senderUser, receiverUserData, text, timeSent, receiverUserId);
      _saveMessageToMessageSubCollection(
        receiverUserId: receiverUserId,
        text: text,
        timesent: timeSent,
        messageType: MessageEnum.text,
        messageId: messageId,
        recieverUsername: receiverUserData.name,
        username: senderUser.name,
      );
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }

  void sendFileMessage({
    required BuildContext context,
    required File file,
    required String receiverUserId,
    required UserModel senderUserData,
    required ProviderRef ref,
    required MessageEnum messageEnum,
  }) async {
    try {
      var timeSent = DateTime.now();
      var messageId = const Uuid().v1();
      String imageUrl = await ref
          .read(commonFirebaseStorageRepositoryProvider)
          .storeFileToFirebase(
            'chat/${messageEnum.type}/${senderUserData.uid}/${receiverUserId}/$messageId',
            file,
          );

      UserModel receiverUserData;
      var userDataMap =
          await firestore.collection('users').doc(receiverUserId).get();
      receiverUserData = UserModel.fromMap(userDataMap.data()!);
      String contactMsg;
      switch (messageEnum) {
        case MessageEnum.image:
          contactMsg = '📷 Photo';
          break;
        case MessageEnum.video:
          contactMsg = '📸 Video';
          break;
        case MessageEnum.audio:
          contactMsg = '♫  Audio';
          break;
        case MessageEnum.gif:
          contactMsg = 'GIF';
          break;
        default:
          contactMsg = 'GIF';
      }

      _saveDataToContactsSubCollection(
        senderUserData,
        receiverUserData,
        contactMsg,
        timeSent,
        receiverUserId,
      );
      _saveMessageToMessageSubCollection(
          receiverUserId: receiverUserId,
          text: imageUrl,
          timesent: timeSent,
          messageId: messageId,
          username: senderUserData.name,
          recieverUsername: receiverUserData.name,
          messageType: messageEnum);
    } catch (e) {
      showSnackBar(context: context, content: e.toString());
    }
  }
}
