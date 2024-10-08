import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/utilities/assets_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:provider/provider.dart';

import '../providers/authentication_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _phoneNumberController =
      TextEditingController(text: '');

  String phoneNumber = '';
  

  Country selectedCountry = Country(
      phoneCode: '1',
      countryCode: 'US',
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: 'USA',
      example: 'USA',
      displayName: 'USA',
      displayNameNoCountryCode: 'US',
      e164Key: '');

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _authProvider = context.watch<AuthenticationProvider>();
    return Scaffold(
        body: SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            children: [
              SizedBox(
                height: 50,
              ),
              SizedBox(
                height: 200,
                width: 200,
                child: Lottie.asset(AssetsManager.chatBubble),
              ),
              Text('Flutter Chat Pro',
                  style: GoogleFonts.openSans(
                      fontSize: 28, fontWeight: FontWeight.w500)),
              SizedBox(
                height: 20,
              ),
              Text(
                'Add your phone number will send you a code to verify',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                    fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: _phoneNumberController,
                maxLength: 10,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onChanged: (String value) {
                  setState(() {
                    phoneNumber = value;
                  });
                },
                decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Phone Number',
                    hintStyle: GoogleFonts.openSans(
                        fontSize: 16, fontWeight: FontWeight.w500),
                    prefixIcon: Container(
                      padding: EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
                      child: InkWell(
                        onTap: () {
                          showCountryPicker(
                              context: context,
                              showPhoneCode: true,
                              onSelect: (Country country) {
                                setState(() {
                                  selectedCountry = country;
                                });
                              });
                        },
                        child: Text(
                          '${selectedCountry.flagEmoji} +${selectedCountry.phoneCode}',
                          style: GoogleFonts.openSans(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    suffixIcon: phoneNumber.length > 9
                        ? _authProvider.isLoading
                            ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            )
                            : InkWell(
                                onTap: () {
                                  //sign in with phone number
                                  _authProvider.signInWithPhoneNumber(
                                      phoneNumber:
                                          '+${selectedCountry.phoneCode}${phoneNumber}',
                                      context: context);
                                },
                                child: Container(
                                  height: 35,
                                  width: 35,
                                  margin: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle),
                                  child: const Icon(
                                    Icons.done,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                              )
                        : SizedBox.shrink(),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
              )
            ],
          ),
        ),
      ),
    ));
  }
}
