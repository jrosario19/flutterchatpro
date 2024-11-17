import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/providers/authentication_provider.dart';
import 'package:flutter_chat_pro/utilities/global_methods.dart';
import 'package:flutter_chat_pro/widgets/app_bar_back_button.dart';
import 'package:flutter_chat_pro/widgets/display_user_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel;

    //get data from arguments
    final uid = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
        appBar: AppBar(
          leading: AppBarBackButton(onPressed: () {
            Navigator.pop(context);
          }),
          centerTitle: true,
          title: Text('Profile Screen'),
          actions: [
            //logout button
            currentUser!.uid == uid
                ? IconButton(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        Constants.settingsScreen,
                        arguments: uid,
                      );
                    },
                    icon: Icon(Icons.settings),
                  )
                : SizedBox()
          ],
        ),
        body: StreamBuilder(
          stream:
              context.read<AuthenticationProvider>().userStream(userId: uid),
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final userModel = UserModel.fromMap(
                snapshot.data!.data() as Map<String, dynamic>);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: userImageWidget(
                          imageUrl: userModel.image, radiis: 60, onTap: () {}),
                    ),
                    SizedBox(height: 20),
                    Text(
                      userModel.name,
                      style: GoogleFonts.openSans(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    buildFriendRequestButton(
                        currentUser: currentUser, userModel: userModel),
                    SizedBox(height: 10),
                    buildFriendsButton(
                        currentUser: currentUser, userModel: userModel),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'About Me',
                          style: GoogleFonts.openSans(
                              fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      userModel.aboutMe,
                      style: GoogleFonts.openSans(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    )
                  ],
                ),
              ),
            );
          },
        ));
  }

  Widget buildFriendRequestButton(
      {required UserModel currentUser, required UserModel userModel}) {
    {
      if (currentUser.uid == userModel.uid &&
          currentUser.friendRequestsUIDs.isNotEmpty) {
        return buildElevatedButton(
            onPressed: () async {
              //navigate to friend request screen
              await Navigator.pushNamed(
                context,
                Constants.friendRequestsScreen,
              );
            },
            label: 'View Friend Requests',
            backgroundColor: Theme.of(context).cardColor,
            textColor: Theme.of(context).colorScheme.primary,
            width: MediaQuery.of(context).size.width * 0.7);
      } else {
        //not in our profile
        return SizedBox.shrink();
      }
    }
  }

  //friends button

  Widget buildFriendsButton(
      {required UserModel currentUser, required UserModel userModel}) {
    if (currentUser.uid == userModel.uid && userModel.friendsUIDs.isNotEmpty) {
      return buildElevatedButton(
          onPressed: () async {
            //navigate to friend request screen
            await Navigator.pushNamed(
              context,
              Constants.friendsScreen,
            );
          },
          label: 'View Friends',
          backgroundColor: Theme.of(context).cardColor,
          textColor: Theme.of(context).colorScheme.primary,
          width: MediaQuery.of(context).size.width * 0.7);
    } else {
      if (currentUser.uid != userModel.uid) {
        if (userModel.friendRequestsUIDs.contains(currentUser.uid)) {
          return buildElevatedButton(
              onPressed: () async {
                //send a friend request
                await context
                    .read<AuthenticationProvider>()
                    .cancelFriendRequest(friendId: userModel.uid)
                    .whenComplete(() {
                  showSnackBar(context, 'Friend request cancelled');
                });
              },
              label: 'Cancel Friend Request',
              backgroundColor: Theme.of(context).cardColor,
              textColor: Theme.of(context).colorScheme.primary,
              width: MediaQuery.of(context).size.width * 0.7);
        } else if (userModel.sentFriendRequestsUIDs.contains(currentUser.uid)) {
          return buildElevatedButton(
              onPressed: () async {
                //send a friend request
                await context
                    .read<AuthenticationProvider>()
                    .acceptFriendRequest(friendId: userModel.uid)
                    .whenComplete(() {
                  showSnackBar(
                      context, 'You are now friends with ${userModel.name}');
                });
              },
              label: 'Acept Friend Request',
              backgroundColor: Theme.of(context).cardColor,
              textColor: Theme.of(context).colorScheme.primary,
              width: MediaQuery.of(context).size.width * 0.7);
        } else if (userModel.friendsUIDs.contains(currentUser.uid)) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildElevatedButton(
                  onPressed: () async {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              title: Text(
                                'Are you sure you want to unfriend ${userModel.name}?',
                                textAlign: TextAlign.center,
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('Cancel')),
                                TextButton(
                                    onPressed: () async {
                                      //send a friend request
                                      await context
                                          .read<AuthenticationProvider>()
                                          .removeFriend(friendId: userModel.uid)
                                          .whenComplete(() {
                                        showSnackBar(context,
                                            'You are no longer friends with ${userModel.name}');
                                        Navigator.pop(context);
                                      });
                                    },
                                    child: Text('Yes'))
                              ],
                            ));
                  },
                  width: MediaQuery.of(context).size.width * 0.4,
                  label: 'Unfriend',
                  backgroundColor: Theme.of(context).cardColor,
                  textColor: Colors.white),
              buildElevatedButton(
                  onPressed: () {
                    //navigate to chat screen
                    Navigator.pushNamed(context, Constants.chatScreen,
                        arguments: {
                          Constants.contactUID: userModel.uid,
                          Constants.contactName: userModel.name,
                          Constants.contactImage: userModel.image,
                          Constants.groupId: '',
                        });
                  },
                  width: MediaQuery.of(context).size.width * 0.4,
                  label: 'Chat',
                  backgroundColor: Theme.of(context).cardColor,
                  textColor: Theme.of(context).colorScheme.primary)
            ],
          );
        } else {
          return buildElevatedButton(
              onPressed: () async {
                await context
                    .read<AuthenticationProvider>()
                    .sendFriendRequest(friendId: userModel.uid)
                    .whenComplete(() {
                  showSnackBar(context, 'Friend request sent');
                });
              },
              label: 'Send Friend Request',
              backgroundColor: Theme.of(context).cardColor,
              textColor: Theme.of(context).colorScheme.primary,
              width: MediaQuery.of(context).size.width * 0.7);
        }
      } else {
        return SizedBox.shrink();
      }
    }
  }

  Widget buildElevatedButton(
      {required VoidCallback onPressed,
      required String label,
      double width = 0.7,
      required Color backgroundColor,
      required Color textColor}) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              elevation: 5,
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15))),
          onPressed: onPressed,
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.openSans(
                fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
          )),
    );
  }
}
