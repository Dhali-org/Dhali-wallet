import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/dhali_wallet_widget.dart';
import 'package:dhali_wallet/firebase_options.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  DhaliWallet? _wallet;
  bool _activated = false;
  Key _key = UniqueKey();

  void _activateWallet() {
    setState(() {
      _activated = true;
    });
  }

  void _removeFloatingActionButton() {
    setState(() {
      _key = UniqueKey();
      _activated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: WalletHomeScreen(
          isImported: false,
          title: "wallet",
          getWallet: () {
            return _wallet;
          },
          setWallet: (DhaliWallet? wallet) {
            _wallet = wallet;
          },
          onActivation: _activateWallet,
        ),
        floatingActionButton: _activated
            ? FloatingActionButton.extended(
                backgroundColor: Color.fromARGB(255, 255, 0, 212),
                label: Text("Press me to make me disappear!"),
                onPressed: _removeFloatingActionButton,
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MainApp());
}
