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

     await _firestore.collection(Constants.users).doc(userModel.uid).set(userModel.toMap());
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
}
