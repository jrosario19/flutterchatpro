import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chat_pro/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_chat_pro/utilities/global_methods.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class AuthenticationProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSucessfull = false;
  String? _uid;
  String? _phoneNumber;
  UserModel? _userModel;

  bool get isLoading => _isLoading;
  bool get isSucessfull => _isSucessfull;
  String? get uid => _uid;
  String? get phoneNumber => _phoneNumber;
  UserModel? get userModel => _userModel;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  //check authentication state
  Future<bool> checkAuthenticationState() async {
    bool isSignedIn = false;
    await Future.delayed(const Duration(seconds: 2));
    if (_auth.currentUser != null) {
      _uid = _auth.currentUser!.uid;

      await getUserDataFromFireStore();
      await saveUserDataToShredPreferences();
      notifyListeners();
      isSignedIn = true;
    } else {
      isSignedIn = false;
    }
    return isSignedIn;
  }

  //check if user exxists
  Future<bool> checkIfUserExists() async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(_uid).get();
    if (documentSnapshot.exists) {
      return true;
    } else {
      return false;
    }
  }

  //set user online status
  Future<void> updateUserStatus({required bool isOnline}) async {
    await _firestore
        .collection(Constants.users)
        .doc(_auth.currentUser!.uid)
        .update({Constants.isOnline: isOnline}); 
  }

  //get user data from firestore
  Future<void> getUserDataFromFireStore() async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(_uid).get();
    _userModel =
        UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    notifyListeners();
  }

  //save user data to shared preferences
  Future<void> saveUserDataToShredPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        Constants.userModel, jsonEncode(userModel!.toMap()));
  }

  //get user data from shared preferences
  Future<void> getUserDataFromSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userJson = sharedPreferences.getString(Constants.userModel) ?? '';
    _userModel = UserModel.fromMap(jsonDecode(userJson));
    _uid = _userModel!.uid;
    notifyListeners();
  }

  //sign in with Phone Number
  Future<void> signInWithPhoneNumber(
      {required String phoneNumber, required BuildContext context}) async {
    _isLoading = true;
    notifyListeners();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential).then((value) async {
          _uid = value.user!.uid;
          _phoneNumber = value.user!.phoneNumber;
          _isSucessfull = true;
          _isLoading = false;
          notifyListeners();
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        _isSucessfull = false;
        _isLoading = false;
        notifyListeners();
        showSnackBar(context, e.toString());
      },
      codeSent: (String verificationId, int? resendToke) {
        _isLoading = false;
        notifyListeners();
        //navigate to OTP screen
        Navigator.of(context).pushNamed(Constants.otpScreen, arguments: {
          Constants.verificationId: verificationId,
          Constants.phoneNumber: phoneNumber
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  // verify OTP code
  Future<void> verifyOTPCode(
      {required String verificationId,
      required String otpCode,
      required BuildContext context,
      required Function onSucess}) async {
    _isLoading = true;
    notifyListeners();
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );
    await _auth.signInWithCredential(credential).then((value) async {
      _uid = value.user!.uid;
      _phoneNumber = value.user!.phoneNumber;
      _isSucessfull = true;
      _isLoading = false;
      onSucess();
      notifyListeners();
      //get user data from firestore
    }).catchError((e) {
      _isSucessfull = false;
      _isLoading = false;
      notifyListeners();
      showSnackBar(context, e.toString());
    });
  }

  //save user data to firestore
  void saveUserDataToFireStore(
      {required UserModel userModel,
      required File? fileImage,
      required Function onSucess,
      required Function onFail}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (fileImage != null) {
        String imageUrl = await uploadFileToFirebaseStorage(
            file: fileImage,
            reference: '${Constants.userImages}/${userModel.uid}');
        userModel.image = imageUrl;
      }

      userModel.lastSeen = DateTime.now().microsecondsSinceEpoch.toString();
      userModel.createdAt = DateTime.now().microsecondsSinceEpoch.toString();

      _userModel = userModel;
      _uid = userModel.uid;

      await _firestore
          .collection(Constants.users)
          .doc(userModel.uid)
          .set(userModel.toMap());
      _isLoading = false;
      onSucess();
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      onFail(e.toString());
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

  //get user stream from firestore
  Stream<DocumentSnapshot> userStream({required String userId}) {
    return _firestore.collection(Constants.users).doc(userId).snapshots();
  }

  //get all users stream from firestore
  Stream<QuerySnapshot> getAllUsersStream({required String userId}) {
    return _firestore
        .collection(Constants.users)
        .where(Constants.uid, isNotEqualTo: userId)
        .snapshots();
  }

  //send a friend request
  Future<void> sendFriendRequest({required String friendId}) async {
    try {
      await _firestore.collection(Constants.users).doc(friendId).update({
        Constants.friendRequestsUIDs: FieldValue.arrayUnion([_uid])
      });
      //add friend uid to our friend requests sent list
      await _firestore.collection(Constants.users).doc(_uid).update({
        Constants.sentFriendRequestsUIDs: FieldValue.arrayUnion([friendId])
      });
    } on FirebaseException catch (e) {
      print(e.toString());
    }
  }

  Future<void> cancelFriendRequest({required String friendId}) async {
    try {
      _firestore.collection(Constants.users).doc(friendId).update({
        Constants.friendRequestsUIDs: FieldValue.arrayRemove([_uid])
      });
      _firestore.collection(Constants.users).doc(_uid).update({
        Constants.sentFriendRequestsUIDs: FieldValue.arrayRemove([friendId])
      });
    } on FirebaseException catch (e) {
      print(e.toString());
    }
  }

  Future<void> acceptFriendRequest({required String friendId}) async {
    try {
      await _firestore.collection(Constants.users).doc(friendId).update({
        Constants.friendsUIDs: FieldValue.arrayUnion([_uid])
      });
      await _firestore.collection(Constants.users).doc(_uid).update({
        Constants.friendsUIDs: FieldValue.arrayUnion([friendId])
      });
      await _firestore.collection(Constants.users).doc(friendId).update({
        Constants.sentFriendRequestsUIDs: FieldValue.arrayRemove([_uid])
      });
      await _firestore.collection(Constants.users).doc(_uid).update({
        Constants.friendRequestsUIDs: FieldValue.arrayRemove([friendId])
      });
    } on FirebaseException catch (e) {
      print(e.toString());
    }
  }

  Future<void> removeFriend({required String friendId}) async {
    try {
      await _firestore.collection(Constants.users).doc(friendId).update({
        Constants.friendsUIDs: FieldValue.arrayRemove([_uid])
      });
      await _firestore.collection(Constants.users).doc(_uid).update({
        Constants.friendsUIDs: FieldValue.arrayRemove([friendId])
      });
    } on FirebaseException catch (e) {
      print(e.toString());
    }
  }

  //get a list of friends
  Future<List<UserModel>> getFriendsList(String uid) async {
    List<UserModel> friendsList = [];

    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(uid).get();
    List<dynamic> friendsUIDs = documentSnapshot.get(Constants.friendsUIDs);

    for (String friendId in friendsUIDs) {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constants.users).doc(friendId).get();
      UserModel userModel =
          UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
      friendsList.add(userModel);
    }
    return friendsList;
  }

  //get a list of friend requests
  Future<List<UserModel>> getFriendRequestsList(String uid) async {
    List<UserModel> friendRequestsList = [];

    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(uid).get();
    List<dynamic> friendRequestsUIDs =
        documentSnapshot.get(Constants.friendRequestsUIDs);
    for (String friendId in friendRequestsUIDs) {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constants.users).doc(friendId).get();
      UserModel userModel =
          UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
      friendRequestsList.add(userModel);
    }
    return friendRequestsList;
  }

  logout() async {
    await _auth.signOut();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    notifyListeners();
  }
}
