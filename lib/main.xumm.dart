import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/dhali_wallet_widget.dart';
import 'package:flutter/material.dart';
import 'package:dhali_wallet/xrpl_wallet_widget.dart';
import 'package:dhali_wallet/widgets/buttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dhali Xumm',
      theme: ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0000FF),
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dhali payment claims'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DhaliWallet? _wallet;
  bool _loggedIn = false;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    bool isDesktop = MediaQuery.of(context).size.width > 720;
    double fontSize = isDesktop ? 16 : 10;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0000FF),
        leading: const Icon(
          Icons.warning,
          color: Colors.red,
        ),
        title: Text(
          "Use testnet wallets in Xumm: \n"
          "1. Toggle developer mode,  2. Select "
          "XRPL testnet",
          softWrap: true,
          style: TextStyle(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: !_loggedIn
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  getTextButton("Sign in to XUMM", textSize: fontSize,
                      onPressed: () {
                    setState(() {
                      _loggedIn = true;
                    });
                  })
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  XRPLWalletWidget(
                    onActivation: null,
                    walletType: Wallet.XummWallet,
                    getWallet: () => _wallet,
                    setWallet: (wallet) {
                      _wallet = wallet;
                    },
                    isDesktop: MediaQuery.of(context).size.width > 720,
                  ),
                ],
              ),
      ),
    );
  }
}
