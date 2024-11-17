import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_chat_pro/utilities/global_methods.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/authentication_provider.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            //copertino search bar
            CupertinoSearchTextField(
              onChanged: (value) {},
              placeholder: 'Search',
            ),
            // list of people
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
              stream: context
                  .read<AuthenticationProvider>()
                  .getAllUsersStream(userId: currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Center(child: Text('Something went wrong')),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Center(
                        child: Text('No users found',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.openSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2))),
                  );
                }
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: userImageWidget(
                            imageUrl: snapshot.data!.docs[index]
                                [Constants.image],
                            radiis: 40,
                            onTap: () {}),
                        title: Text(
                          snapshot.data!.docs[index][Constants.name],
                        ),
                        subtitle: Text(
                          snapshot.data!.docs[index][Constants.aboutMe],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          //navigate to profile screen with uid as argument
                          Navigator.pushNamed(
                            context,
                            Constants.profileScreen,
                            arguments: snapshot.data!.docs[index].id,
                          );
                        },
                      );
                    },
                  );
                }
                return const Center(
                  child: Text('No data'),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}
