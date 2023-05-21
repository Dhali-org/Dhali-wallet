import 'package:dhali_wallet/dhali_wallet_widget.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  XRPLWallet? _wallet;
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: WalletHomeScreen(
        isImported: false,
        bodyTextColor: Color.fromARGB(255, 255, 255, 255),
        buttonsColor: Color.fromARGB(255, 255, 0, 212),
        title: "wallet",
        getWallet: () {
          return _wallet;
        },
        setWallet: (XRPLWallet wallet) {
          _wallet = wallet;
        },
      ),
    ),
  );
}
