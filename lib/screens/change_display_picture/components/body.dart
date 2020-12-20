import 'dart:io';

import 'package:e_commerce_app_flutter/components/default_button.dart';
import 'package:e_commerce_app_flutter/constants.dart';
import 'package:e_commerce_app_flutter/services/authentification/authentification_service.dart';
import 'package:e_commerce_app_flutter/services/local_files_access/local_files_access_service.dart';
import 'package:e_commerce_app_flutter/size_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider_models/body_model.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BodyState>(
      create: (context) => BodyState(),
      child: SingleChildScrollView(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
          child: SizedBox(
            width: double.infinity,
            child: Consumer<BodyState>(
              builder: (context, bodyState, child) {
                return Column(
                  children: [
                    Text(
                      "Change Avatar",
                      style: headingStyle,
                    ),
                    SizedBox(height: getProportionateScreenHeight(40)),
                    GestureDetector(
                      child: buildDisplayPictureAvatar(context, bodyState),
                      onTap: () {
                        getImageFromUser(context, bodyState);
                      },
                    ),
                    SizedBox(height: getProportionateScreenHeight(80)),
                    buildChosePictureButton(context, bodyState),
                    SizedBox(height: getProportionateScreenHeight(30)),
                    buildUploadPictureButton(context, bodyState),
                    SizedBox(height: getProportionateScreenHeight(80)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDisplayPictureAvatar(BuildContext context, BodyState bodyState) {
    return CircleAvatar(
      radius: SizeConfig.screenWidth * 0.305,
      backgroundColor: kPrimaryColor,
      child: CircleAvatar(
        radius: SizeConfig.screenWidth * 0.3,
        backgroundColor: kTextColor.withOpacity(0.15),
        backgroundImage: bodyState.chosenImage == null
            ? ((AuthentificationService().currentUser.photoURL == null)
                ? null
                : NetworkImage(AuthentificationService().currentUser.photoURL))
            : MemoryImage(bodyState.chosenImage.readAsBytesSync()),
      ),
    );
  }

  void getImageFromUser(BuildContext context, BodyState bodyState) async {
    final path = await choseImageFromLocalFiles(context);
    if (path == READ_STORAGE_PERMISSION_DENIED) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Storage permissions required")));
      return;
    } else if (path == INVALID_FILE_CHOSEN) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Invalid Image")));
      return;
    } else if (path == FILE_SIZE_OUT_OF_BOUNDS) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("File size should be within 5KB to 1MB only")));
      return;
    }
    bodyState.setChosenImage = File(path);
  }

  Widget buildChosePictureButton(BuildContext context, BodyState bodyState) {
    return DefaultButton(
      text: "Choose Picture",
      press: () {
        getImageFromUser(context, bodyState);
      },
    );
  }

  Widget buildUploadPictureButton(BuildContext context, BodyState bodyState) {
    return DefaultButton(
      text: "Upload Picture",
      press: () {
        uploadImageToFirestorage(context, bodyState);
      },
    );
  }

  Future<void> uploadImageToFirestorage(
      BuildContext context, BodyState bodyState) async {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Updating Display Picture, Please wait")));
    final Reference firestorageRef = FirebaseStorage.instance.ref();
    final String currentUserUid = AuthentificationService().currentUser.uid;
    final snapshot = await firestorageRef
        .child("user/display_picture/$currentUserUid")
        .putFile(bodyState.chosenImage);
    final downloadUrl = await snapshot.ref.getDownloadURL();
    print("Image uploaded at $downloadUrl");

    AuthentificationService().uploadDisplayPictureForCurrentUser(downloadUrl);

    Navigator.pop(context);
  }
}