library dhali_wallet;

import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:dhali_wallet/xumm_wallet.dart';
import 'package:dhali_wallet/xrpl_wallet_widget.dart';
import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Wallet { RawXRPWallet, XummWallet, GemWallet, UnselectedWallet }

class WalletHomeScreen extends StatefulWidget {
  const WalletHomeScreen(
      {super.key,
      required this.title,
      required this.getWallet,
      required this.setWallet,
      this.onActivation,
      this.isImported = true});

  final bool isImported;
  final String title;
  final DhaliWallet? Function() getWallet;
  final Function(DhaliWallet?) setWallet;
  final void Function()? onActivation;

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

// TODO: Metamask-style phrase creation and verification
class _WalletHomeScreenState extends State<WalletHomeScreen>
    with SingleTickerProviderStateMixin {
  // TODO: pull the fields below from wallet
  String _publicKey = "";
  String? _mnemonicState;
  Wallet? _wallet;
  int _tabIndex = 0;
  late TabController _tabController;
  final List<Tab> _tabs = [
    Tab(
      icon: Icon(Icons.wallet),
      text: "Available wallets",
    ),
    Tab(
      icon: Icon(Icons.account_box_outlined),
      text: "Active wallet",
    ),
  ];

  final _mnemonicFormKey = GlobalKey<FormState>();

  setWalletAndRestore(DhaliWallet? wallet) {
    widget.setWallet(wallet);
    _tabIndex = 1;
    SharedPreferences.getInstance().then((pref) async {
      if (wallet != null && wallet.runtimeType == XummWallet) {
        await pref.setString('address', wallet.address).then((address) async {
          await pref.setString('wallet', "XUMM").then((wallet) {
            _wallet = Wallet.XummWallet;
          });
        });
      }
    });
  }

  @override
  void initState() {
    _wallet = Wallet.UnselectedWallet;
    if (widget.getWallet() is XRPLWallet) {
      _tabIndex = 1;
      _wallet = Wallet.RawXRPWallet;
    } else if (widget.getWallet() is XummWallet) {
      _tabIndex = 1;
      _wallet = Wallet.XummWallet;
    }
    _tabController = TabController(
        vsync: this, length: _tabs.length, initialIndex: _tabIndex);

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if wallet can be loaded from device
      if (widget.getWallet() == null) {
        SharedPreferences.getInstance().then((value) {
          final walletString = value.getString('wallet');
          if (walletString != null && widget.onActivation != null) {
            widget.onActivation!();
          }
          if (walletString == "XUMM") {
            String? address = value.getString('address');
            if (address != null) {
              final wallet = XummWallet(address,
                  getFirestore: () => FirebaseFirestore.instance,
                  testMode: true);
              setWalletAndRestore(wallet);
              _tabController.animateTo(1);
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if wallet can be loaded from device

    return Scaffold(
        appBar: TabBar(
          indicatorWeight: 12.0,
          controller: _tabController,
          tabs: _tabs,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            AllWallets(),
            getScreenView(_wallet),
          ],
        ));
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
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _mnemonicState = bip39.generateMnemonic();
                              var wallet = XRPLWallet(_mnemonicState!,
                                  getFirestore: () =>
                                      FirebaseFirestore.instance,
                                  testMode: true);
                              setWalletAndRestore(wallet);
                              _publicKey = wallet.publicKey();
                              final dataUri =
                                  'data:text/plain;charset=utf-8,${(widget.getWallet() as XRPLWallet).mnemonic!}';
                              html.document.createElement('a')
                                  as html.AnchorElement
                                ..href = dataUri
                                ..download = 'dhali_xrp_wallet_secret_words.txt'
                                ..dispatchEvent(html.Event.eventType(
                                    'MouseEvent', 'click'));
                              if (widget.onActivation != null) {
                                widget.onActivation!();
                              }
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 50.0, vertical: 25),
                            child: Text(
                              'Generate new test wallet',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text("or", style: TextStyle(fontSize: 25)),
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
                        child: ElevatedButton(
                          onPressed: () {
                            if (_mnemonicState != null) {
                              // TODO: 'testMode' to 'false' for release
                              var wallet = XRPLWallet(_mnemonicState!,
                                  getFirestore: () =>
                                      FirebaseFirestore.instance,
                                  testMode: true);
                              setWalletAndRestore(wallet);
                              _publicKey = wallet.publicKey();
                              if (widget.onActivation != null) {
                                widget.onActivation!();
                              }
                            }
                            setState(() {});
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 50.0, vertical: 25),
                            child: Text(
                              'Retrieve test wallet',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
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
        if (widget.getWallet() is! XRPLWallet) {
          screen = CreateRawXRPLWallet();
        } else {
          screen = XRPLWalletWidget(
            walletType: Wallet.RawXRPWallet,
            getWallet: widget.getWallet,
            setWallet: setWalletAndRestore,
            onActivation: widget.onActivation,
          );
        }
        break;
      case Wallet.XummWallet:
        screen = XRPLWalletWidget(
          walletType: Wallet.XummWallet,
          getWallet: widget.getWallet,
          setWallet: setWalletAndRestore,
          onActivation: widget.onActivation,
        );

        break;
      case Wallet.GemWallet:
        screen = XRPLWalletWidget(
          walletType: Wallet.GemWallet,
          getWallet: widget.getWallet,
          setWallet: setWalletAndRestore,
          onActivation: widget.onActivation,
        );
        break;
      default:
        screen = UnselectedWallet();
        break;
    }
    return screen;
  }

  Widget AllWallets() {
    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(
              height: 50,
            ),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Link a wallet to continue ',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                )),
            const SizedBox(
              height: 50,
            ),
          ]),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final wallet = Wallet.values[index];

              Widget image;
              String text;
              Widget spacer;
              Key key;
              double spacer_height = 10;
              double button_height = 60;
              double icon_height = 50;
              double button_width = 250;

              if (wallet == Wallet.XummWallet) {
                key = Key("xumm_wallet_tile");
                image = Image.asset(
                    widget.isImported
                        ? 'packages/dhali_wallet/assets/images/xumm.png'
                        : 'assets/images/xumm.png',
                    height: icon_height);
                text = " Link XUMM wallet";
                spacer = SizedBox(height: spacer_height);
              } else if (wallet == Wallet.RawXRPWallet) {
                key = Key("raw_xrp_wallet_tile");
                image = Image.asset(
                  widget.isImported
                      ? 'packages/dhali_wallet/assets/images/xrp.png'
                      : 'assets/images/xrp.png',
                  height: icon_height,
                );
                text = " Use free test wallet";
                spacer = Column(children: [
                  SizedBox(height: spacer_height),
                  const Text(
                    "or",
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: spacer_height)
                ]);
              } else {
                key = Key("gem_wallet_tile");
                image = Image.asset(
                    widget.isImported
                        ? 'packages/dhali_wallet/assets/images/gem.png'
                        : 'assets/images/gem.png',
                    height: icon_height);
                text = " Link GemWallet";
                spacer = SizedBox(height: spacer_height);
              }

              return Column(children: [
                ElevatedButton(
                  key: key,
                  onPressed: () {
                    setState(() {
                      _wallet = wallet;
                      if (_tabController != null) {
                        _tabController
                            .animateTo(1); // Switch to the second tab (index 1)
                      }
                    });
                    // handle the button press
                  },
                  child: SizedBox(
                      width: button_width,
                      height: button_height,
                      child: OverflowBox(
                          maxWidth: double.infinity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              image,
                              SizedBox(width: 10),
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              )
                            ],
                          ))),
                ),
                spacer
              ]);
            },
            childCount: Wallet.values.length - 1,
          ),
        ),
      ],
    );
  }

  Widget UnselectedWallet() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You must choose a wallet ',
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          Icon(
            Icons.warning,
            size: 24,
            color: Colors.red,
          )
        ],
      ),
      SizedBox(height: 50),
      ElevatedButton(
        onPressed: () {
          setState(() {
            if (_tabController != null) {
              _tabController.animateTo(0);
            }
          });
          // handle the button press
        },
        child: SizedBox(
            width: 400,
            height: 50,
            child: Center(
              child: Text(
                "Choose a wallet",
                style: TextStyle(
                  fontSize: 24,
                ),
                // style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            )),
      )
    ]));
  }
}
