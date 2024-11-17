import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_pro/constants.dart';
import 'package:flutter_chat_pro/models/user_model.dart';
import 'package:flutter_chat_pro/utilities/global_methods.dart';
import 'package:provider/provider.dart';

import '../providers/authentication_provider.dart';

class FriendsLIst extends StatelessWidget {
  const FriendsLIst({super.key, required this.viewTpe});
  final FriendViewType viewTpe;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    final future = viewTpe == FriendViewType.friends
        ? context.read<AuthenticationProvider>().getFriendsList(uid)
        : viewTpe == FriendViewType.friendRequests
            ? context.read<AuthenticationProvider>().getFriendRequestsList(uid)
            : context.read<AuthenticationProvider>().getFriendsList(uid);

    return FutureBuilder<List<UserModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No friends yet'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                    contentPadding: EdgeInsets.only(left: -10),
                    leading: userImageWidget(
                        imageUrl: snapshot.data![index].image,
                        radiis: 40,
                        onTap: () {
                          Navigator.pushNamed(context, Constants.profileScreen,
                              arguments: snapshot.data![index].uid);
                        }),
                    title: Text(snapshot.data![index].name),
                    subtitle: Text(
                      snapshot.data![index].aboutMe,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {},
                    trailing: ElevatedButton(
                      onPressed: () async {
                        if (viewTpe == FriendViewType.friends) {
                          Navigator.pushNamed(context, Constants.chatScreen,
                              arguments: {
                                Constants.contactUID: snapshot.data![index].uid,
                                Constants.contactName:
                                    snapshot.data![index].name,
                                Constants.contactImage:
                                    snapshot.data![index].image,
                                Constants.groupId: '',
                              });
                        } else if (viewTpe == FriendViewType.friendRequests) {
                          await context
                              .read<AuthenticationProvider>()
                              .acceptFriendRequest(
                                  friendId: snapshot.data![index].uid)
                              .whenComplete(() {
                            showSnackBar(context,
                                'You are now friends with ${snapshot.data![index].name}');
                          });
                        } else {
                          //check the checckbox
                        }
                      },
                      child: viewTpe == FriendViewType.friends
                          ? Text('Chat')
                          : Text('Accept'),
                    ));
              },
            );
          }
        });
  }
}
