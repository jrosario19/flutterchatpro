import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/authentication_provider.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String? otpCode;

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final phoneNumber = args[Constants.phoneNumber] as String;
    final verificationId = args[Constants.verificationId] as String;

    final authProvider = context.watch<AuthenticationProvider>();

    final defaultPinTheme = PinTheme(
        width: 56,
        height: 60,
        textStyle:
            GoogleFonts.openSans(fontSize: 22, fontWeight: FontWeight.w600),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.transparent)));
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  Text('Vefification',
                      style: GoogleFonts.openSans(
                          fontSize: 28, fontWeight: FontWeight.w500)),
                  SizedBox(
                    height: 50,
                  ),
                  Text('Enter the 6-digit code sent to the number',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                          fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(
                    height: 10,
                  ),
                  Text(phoneNumber,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                          fontSize: 18, fontWeight: FontWeight.w500)),
                  SizedBox(
                    height: 30,
                  ),
                  SizedBox(
                      height: 68,
                      child: Pinput(
                        length: 6,
                        controller: controller,
                        focusNode: focusNode,
                        defaultPinTheme: defaultPinTheme,
                        onCompleted: (pin) {
                          setState(() {
                            otpCode = pin;
                          });
                          //verify the otp code
                          verifyOTPCode(
                              otpCode: otpCode!,
                              verificationId: verificationId);
                        },
                        focusedPinTheme: defaultPinTheme.copyWith(
                            height: 68,
                            width: 64,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                                border: Border.all(color: Colors.deepPurple))),
                        errorPinTheme: defaultPinTheme.copyWith(
                            height: 68,
                            width: 64,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                                border: Border.all(color: Colors.red))),
                      )),
                  SizedBox(
                    height: 30,
                  ),
                  authProvider.isLoading
                      ? CircularProgressIndicator()
                      : SizedBox.shrink(),
                  authProvider.isSucessfull
                      ? Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.done,
                            color: Colors.white,
                            size: 30,
                          ))
                      : Container(),
                  authProvider.isLoading
                      ? SizedBox.shrink()
                      : Text(
                          'Didn\'t received the code?',
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                          ),
                        ),
                  SizedBox(
                    height: 10,
                  ),
                  authProvider.isLoading
                      ? SizedBox.shrink()
                      : TextButton(
                          onPressed: () {
                            //TODO: resend the otp code
                          },
                          child: Text(
                            'Resend code',
                            style: GoogleFonts.openSans(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void verifyOTPCode(
      {required String otpCode, required String verificationId}) async {
    //verify the otp code
    final authProvider = context.read<AuthenticationProvider>();
    authProvider.verifyOTPCode(
        verificationId: verificationId,
        otpCode: otpCode,
        context: context,
        onSucess: () async {
          //1. check if the user is new or not in firestore
          bool userExists = await authProvider.checkIfUserExists();

          if (userExists) {
            //2. if the user is not new,

            // * get the user information from the firebase
            await authProvider.getUserDataFromFireStore();

            // * save the user information to provider / shareed preferences
            await authProvider.saveUserDataToShredPreferences();

            // * navigate to the home screen
            navigate(userExists: true);
          } else {
            //3. if the user is new, navigate to the user information screen
            navigate(userExists: false);
          }
        });
  }

  void navigate({required bool userExists}) {
    if (userExists) {
      //navigate to home screen and remove previous screen from the stack
      Navigator.pushNamedAndRemoveUntil(
          context, Constants.homeScreen, (route) => false);
    } else {
      Navigator.pushNamed(context, Constants.userInformationScreen);
    }
  }
}
