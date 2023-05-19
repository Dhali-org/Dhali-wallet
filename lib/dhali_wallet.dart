library dhali_wallet;

import 'dart:convert';
import 'dart:html' as html;

import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;

enum Wallet {
  RawXRPWallet,
  XummWallet,
  Fynbos,
  MetaMask,
  UnselectedWallet,
}

class WalletHomeScreen extends StatefulWidget {
  const WalletHomeScreen(
      {super.key,
      required this.title,
      required this.getWallet,
      required this.setWallet,
      required this.color,
      required this.highlightedColor,
      this.textColor = Colors.black});

  final Color color;
  final Color textColor;
  final Color highlightedColor;
  final String title;
  final XRPLWallet? Function() getWallet;
  final Function(XRPLWallet) setWallet;

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

// TODO: Metamask-style phrase creation and verification
class _WalletHomeScreenState extends State<WalletHomeScreen> {
  // TODO: pull the fields below from wallet
  String _publicKey = "";
  String? _mnemonicState;
  Wallet? _wallet;
  int _tabIndex = 0;

  final _mnemonicFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    _wallet ?? Wallet.UnselectedWallet;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        initialIndex: _tabIndex,
        child: Scaffold(
            appBar: AppBar(
              bottom: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.wallet),
                    text: "Available wallets",
                  ),
                  Tab(
                    icon: Icon(Icons.account_box_outlined),
                    text: "Active wallet",
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                AllWallets(),
                getScreenView(_wallet),
              ],
            )));
  }

  Widget CreateRawXRPLWallet() {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60.0),
              child: Form(
                key: _mnemonicFormKey,
                child: Column(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 25),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            children: <Widget>[
                              Positioned.fill(
                                child: Container(
                                  color: widget.color,
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(.0),
                                  textStyle: const TextStyle(fontSize: 20),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _mnemonicState = bip39.generateMnemonic();
                                    var wallet = XRPLWallet(_mnemonicState!,
                                        testMode: true);
                                    widget.setWallet(wallet);
                                    _publicKey =
                                        widget.getWallet()!.publicKey();
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 50.0, vertical: 25),
                                  child: Text(
                                    'Generate new wallet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '\n\nor\n\n',
                            style: TextStyle(
                                color: widget.textColor, fontSize: 25),
                          ),
                        ],
                      ),
                    ),
                    TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          hintText: "Input your memorable words here.",
                        ),
                        validator: (value) {
                          const String errorMessage =
                              'You must have at least 12 memorable words for your wallet.';
                          if (value == null || value.isEmpty) {
                            return errorMessage;
                          }

                          final whitespaceRegex = RegExp(r"\s+");
                          final leadingWhitespaceRegex = RegExp(r"^\s");
                          final trailingWhitespaceRegex = RegExp(r"\s$");

                          String cleanupWhitespace(String input) => value
                              .replaceAll(whitespaceRegex, " ")
                              .replaceAll(leadingWhitespaceRegex, "")
                              .replaceAll(trailingWhitespaceRegex, "");

                          if (cleanupWhitespace(value).split(' ').length < 12) {
                            return errorMessage;
                          }
                          return null;
                        },
                        onChanged: (String mnemonic) {
                          if (_mnemonicFormKey.currentState!.validate()) {
                            setState(() {
                              _mnemonicState = mnemonic;
                            });
                          } else {
                            setState(() {
                              _mnemonicState = null;
                            });
                          }
                        }),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 25),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            children: <Widget>[
                              Positioned.fill(
                                child: Container(
                                  color: widget.color,
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(.0),
                                  textStyle: const TextStyle(fontSize: 20),
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_mnemonicState != null) {
                                      // TODO: 'testMode' to 'false' for release
                                      var wallet = XRPLWallet(_mnemonicState!,
                                          testMode: true);
                                      widget.setWallet(wallet);
                                      _publicKey =
                                          widget.getWallet()!.publicKey();
                                    }
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 50.0, vertical: 25),
                                  child: Text(
                                    'Retrieve your wallet',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getScreenView(drawerIndex) {
    Future(() => ScaffoldMessenger.of(context).hideCurrentSnackBar());
    Widget screen = UnselectedWallet();

    switch (drawerIndex) {
      case Wallet.RawXRPWallet:
        if (widget.getWallet() == null) {
          screen = CreateRawXRPLWallet();
        } else {
          screen =
              RawXRPWallet(widget.getWallet()!, textColor: widget.textColor);
        }
        break;
      case Wallet.XummWallet:
        screen = Center(
          child: Text(
            "Coming soon!",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        );
        break;
      case Wallet.Fynbos:
        screen = Center(
          child: Text(
            "Coming soon!",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        );
        break;
      case Wallet.MetaMask:
        screen = Center(
          child: Text(
            "Coming soon!",
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        );
        break;
      default:
        screen = UnselectedWallet();
        break;
    }
    return screen;
  }

  Widget AllWallets() {
    return GridView.builder(
        itemCount: Wallet.values.length - 1,
        padding: const EdgeInsets.only(top: 8),
        scrollDirection: Axis.vertical,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 600, childAspectRatio: 2),
        itemBuilder: (BuildContext context, int index) {
          final wallet = Wallet.values[index];

          Image image;
          if (wallet == Wallet.XummWallet) {
            image = Image.asset('assets/images/xumm.png');
          } else if (wallet == Wallet.RawXRPWallet) {
            image = Image.asset('assets/images/xrp.png');
          } else if (wallet == Wallet.Fynbos) {
            image = Image.asset('assets/images/fynbos.png');
          } else {
            image = Image.asset('assets/images/metamask.jpg');
          }

          return GestureDetector(
              onTap: () {
                setState(() {
                  _wallet = wallet;
                  TabController? tabController =
                      DefaultTabController.of(context);
                  if (tabController != null) {
                    tabController
                        .animateTo(1); // Switch to the second tab (index 1)
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: image,
              ));
          ;
        });
  }

  Widget UnselectedWallet() {
    return Center(
      child: Text(
        "Please select a wallet from 'Available wallets'",
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget RawXRPWallet(XRPLWallet wallet,
      {bool hideMnemonic = true, Color textColor = Colors.black}) {
    const double fontSize = 20;
    return Center(
        child: ListView(
      shrinkWrap: true,
      children: <Widget>[
        //const Center(
        //  child: const Padding(
        //padding: EdgeInsets.symmetric(horizontal: 200.0,
        //                        vertical: 100.0),
        //    child: BalanceChart(),
        //  )
        //),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25.0),
            child: ValueListenableBuilder<String?>(
                valueListenable: wallet.balance,
                builder: (BuildContext context, String? balance, Widget? _) {
                  if (balance == null) {
                    return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Loading balance: ",
                              style: TextStyle(fontSize: fontSize)),
                          CircularProgressIndicator()
                        ]);
                  }
                  return SelectableText('Balance: $balance XRP',
                      style: const TextStyle(fontSize: 25));
                }),
          ),
        ),
        Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 25.0),
              child: SelectableText(
                'Classic address: ${wallet.address}',
                style: const TextStyle(fontSize: fontSize),
              )),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SelectableText('Memorable words: ',
                style: const TextStyle(fontSize: fontSize)),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final dataUri =
                    'data:text/plain;charset=utf-8,${widget.getWallet()!.mnemonic!}';
                html.document.createElement('a') as html.AnchorElement
                  ..href = dataUri
                  ..download = 'dhali_xrp_wallet_secret_words.xrp'
                  ..dispatchEvent(html.Event.eventType('MouseEvent', 'click'));
              },
              child: const Icon(
                Icons.download,
                color: Colors.grey,
              ),
            )
          ],
        ),
      ],
    ));
  }
}
