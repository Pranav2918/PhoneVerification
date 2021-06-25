import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:phone_verification/screens/home_screen.dart';

enum MobileVerificationState {
  SHOW_MOBILE_FORM_STATE,
  SHOW_OTP_FORM_STATE,
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  MobileVerificationState currentState =
      MobileVerificationState.SHOW_MOBILE_FORM_STATE;
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  FirebaseAuth _auth = FirebaseAuth.instance;
  late String verificationId;
  bool showLoading = false;

  void signInWithPhoneAuthCredential(
      PhoneAuthCredential phoneAuthCredential) async {
    setState(() {
      showLoading = true;
    });
    try {
      final authCredential =
          await _auth.signInWithCredential(phoneAuthCredential);
      setState(() {
        showLoading = false;
      });
      if (authCredential.user != null) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ));
      }
    } on FirebaseException catch (e) {
      setState(() {
        setState(() {
          showLoading = false;
        });
        _scaffoldKey.currentState!
            .showSnackBar(SnackBar(content: Text(e.message.toString())));
      });
    }
  }

  getMobileFormWidget(context) {
    return Column(
      children: <Widget>[
        Spacer(),
        TextField(
          controller: phoneController,
          decoration: InputDecoration(hintText: "Phone Number"),
        ),
        SizedBox(height: 15),
        // ignore: deprecated_member_use
        FlatButton(
            color: Colors.teal,
            onPressed: () async {
              setState(() {
                showLoading = true;
              });

              await _auth.verifyPhoneNumber(
                  phoneNumber: phoneController.text,
                  verificationCompleted: (phoneAuthCredential) async {
                    setState(() {
                      showLoading = false;
                    });
                    // signInWithPhoneAuthCredential(phoneAuthCredential);
                  },
                  verificationFailed: (verificationFailed) async {
                    setState(() {
                      showLoading = false;
                    });
                    // ignore: deprecated_member_use
                    _scaffoldKey.currentState!.showSnackBar(SnackBar(
                        content: Text(verificationFailed.message.toString())));
                  },
                  codeSent: (verficationId, resendingToken) async {
                    setState(() {
                      showLoading = false;
                      currentState =
                          MobileVerificationState.SHOW_OTP_FORM_STATE;
                      this.verificationId = verficationId;
                    });
                  },
                  codeAutoRetrievalTimeout: (verficationId) async {});
            },
            child: Text('SEND', style: TextStyle(color: Colors.white))),
        Spacer()
      ],
    );
  }

  getOtpFormWidget(context) {
    return Column(children: <Widget>[
      Spacer(),
      TextField(
        controller: otpController,
        decoration: InputDecoration(hintText: "OTP"),
      ),
      SizedBox(height: 15),
      // ignore: deprecated_member_use
      FlatButton(
          color: Colors.teal,
          onPressed: () async {
            PhoneAuthCredential phoneAuthCredential =
                PhoneAuthProvider.credential(
                    verificationId: verificationId, smsCode: otpController.text);
            signInWithPhoneAuthCredential(phoneAuthCredential);
          },
          child: Text('Verify', style: TextStyle(color: Colors.white))),
      Spacer()
    ]);
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        child: showLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : currentState == MobileVerificationState.SHOW_MOBILE_FORM_STATE
                ? getMobileFormWidget(context)
                : getOtpFormWidget(context),
        padding: EdgeInsets.all(30.0),
      ),
    );
  }
}
