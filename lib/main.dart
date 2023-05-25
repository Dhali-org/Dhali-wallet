import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/dhali_wallet_widget.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';

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
          bodyTextColor: Color.fromARGB(255, 255, 255, 255),
          buttonsColor: Color.fromARGB(255, 255, 0, 212),
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
  runApp(MainApp());
}
