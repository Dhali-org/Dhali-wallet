import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  XRPLWallet? _wallet;
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: WalletHomeScreen(
        color: Color(0xFF0000FF),
        textColor: Colors.white,
        highlightedColor: Color(0xFF0000FF),
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
