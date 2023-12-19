import 'dart:convert';
import 'dart:html';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali_wallet/dhali_wallet_widget.dart';
import 'package:dhali_wallet/wallet_types.dart';
import 'package:dhali_wallet/widgets/buttons.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:dhali_wallet/xumm_wallet.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'dart:html' as html;
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class XRPLWalletWidget extends StatefulWidget {
  const XRPLWalletWidget(
      {super.key,
      required this.walletType,
      required this.getWallet,
      required this.setWallet,
      required this.onActivation});

  final void Function()? onActivation;
  final DhaliWallet? Function() getWallet;
  final Function(DhaliWallet?) setWallet;
  final Wallet walletType;

  @override
  State<XRPLWalletWidget> createState() => _XRPLWalletWidgetState();
}

class _XRPLWalletWidgetState extends State<XRPLWalletWidget> {
  double xummTimeout = 0.0;
  bool waiting = false;
  TextEditingController _numberController = TextEditingController();
  String _submittedNumber = '';
  PaymentChannelDescriptor? _descriptor;
  @override
  Widget build(BuildContext context) {
    if (widget.walletType == Wallet.RawXRPWallet) {
      return widget.getWallet() is XRPLWallet ||
              widget.getWallet() is XummWallet
          ? viewAccount()
          : signinXumm();
    } else if (widget.walletType == Wallet.XummWallet) {
      return widget.getWallet() is XummWallet ? viewAccount() : signinXumm();
    } else if (widget.walletType == Wallet.GemWallet) {
      return const Center(
        child: Text('GemWallet coming soon',
            style: TextStyle(
              fontSize: 20,
            )),
      );
    } else {
      throw Error();
    }
  }

  Widget signinXumm() {
    Future<http.Response> response = requestSignIn();

    return FutureBuilder<http.Response>(
      future: response, // Replace with your actual future function
      builder: (BuildContext context, AsyncSnapshot<http.Response> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a loading indicator while the future is resolving
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Display an error message if the future encounters an error
          return Text('Error: ${snapshot.error}');
        } else {
          var data = jsonDecode(snapshot.data!.body) as Map<String, dynamic>;
          displayQRCodeFrom("Scan to connect", context, data);
          poll(
            data["uuid"],
            onSuccess: (http.Response response) {
              Navigator.pop(context);
              XummWallet wallet = XummWallet(
                  jsonDecode(response.body)["response"]["account"],
                  getFirestore: () => FirebaseFirestore.instance,
                  testMode: true);
              setState(() {
                widget.setWallet(
                  wallet,
                );
                widget.onActivation != null ? widget.onActivation!() : null;
              });
            },
            onError: (http.Response response) => {},
            onTimeout: () => {},
          );
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget viewAccount() {
    const double fontSize = 16;
    return Center(
      child: Table(
        defaultColumnWidth: IntrinsicColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              TableCell(
                child: Container(
                  margin: EdgeInsets.all(8),
                  child: Text('Status:',
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.bold)),
                ),
              ),
              TableCell(
                  child: Container(
                margin: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Text(
                      'Linked with ${widget.getWallet() is XRPLWallet ? "XRPL" : "XUMM"} ',
                      style: TextStyle(fontSize: fontSize),
                    ),
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.green,
                    )
                  ],
                ),
              )),
            ],
          ),
          TableRow(
            children: [
              TableCell(
                child: Container(
                  margin: EdgeInsets.all(8),
                  child: Text('Classic address:',
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.bold)),
                ),
              ),
              TableCell(
                child: Container(
                  margin: EdgeInsets.all(8),
                  child:
                      getTextButton("Show", textSize: fontSize, onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Classic address'),
                            content: SelectableText(widget.getWallet()!.address,
                                style: TextStyle(fontSize: fontSize)),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("OK"),
                              ),
                            ],
                          );
                        });
                  }),
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              TableCell(
                child: Container(
                  margin: EdgeInsets.all(8),
                  child: Text('Dhali balance:',
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.bold)),
                ),
              ),
              TableCell(
                  child: Container(
                margin: EdgeInsets.all(8),
                child: Row(
                  children: [
                    ValueListenableBuilder<String?>(
                        valueListenable: widget.getWallet()!.balance,
                        builder:
                            (BuildContext context, String? balance, Widget? _) {
                          if (balance == null) {
                            return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Loading... ",
                                      style: TextStyle(fontSize: fontSize)),
                                  CircularProgressIndicator()
                                ]);
                          }
                          return Text('${double.parse(balance) / 1000000} XRP ',
                              style: TextStyle(fontSize: fontSize));
                        }),
                    IconButton(
                        icon: Icon(Icons.info),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Information'),
                                  content: Text(
                                      'Your Dhali balance is the amount of XRP '
                                      'you have reserved for using the Dhali platform. '),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text("OK"),
                                    ),
                                  ],
                                );
                              });
                        })
                  ],
                ),
              )),
            ],
          ),
          TableRow(
            children: [
              TableCell(
                child: Container(
                  margin: EdgeInsets.all(8),
                  child: TextFormField(
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    controller: _numberController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'XRP amount',
                    ),
                  ),
                ),
              ),
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: getTextButton(
                          'Fund Dhali balance',
                          textSize: fontSize,
                          onPressed: _numberController.text.isEmpty
                              ? null
                              : () async {
                                  bool? fundPaymentChannel = await showDialog<
                                          bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Are you sure?'),
                                          content: Text(
                                              'You are about to fund your Dhali wallet!\n\n'
                                              'You will be able to retrieve unspent funds later.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, true);
                                              },
                                              child: const Text("Yes"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, false);
                                              },
                                              child: const Text("No"),
                                            ),
                                          ],
                                        );
                                      });
                                  if (fundPaymentChannel != null &&
                                      !fundPaymentChannel) {
                                    return;
                                  }

                                  double? number =
                                      double.tryParse(_numberController.text);
                                  if (number != null) {
                                    bool fundingSuccess = false;
                                    if (mounted) {
                                      showDialog<bool>(
                                        context: context,
                                        barrierDismissible:
                                            false, // Disallow dismiss by touching outside
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            actions: [
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        context, false);
                                                  },
                                                  child: Text("Cancel"))
                                            ],
                                            title: Text('Funding channel'),
                                            content: const Row(
                                              children: [
                                                CircularProgressIndicator(),
                                                SizedBox(width: 10),
                                                Text("Please wait..."),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                      number *= 1000000; // Convert to drops
                                      // Valid number, proceed with submission
                                      List<PaymentChannelDescriptor>
                                          channelDescriptors = await widget
                                              .getWallet()!
                                              .getOpenPaymentChannels(
                                                  destination_address:
                                                      "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk");
                                      if (channelDescriptors.isEmpty) {
                                        // TODO : depend on Dhali public address
                                        channelDescriptors = [
                                          await widget
                                              .getWallet()!
                                              .openPaymentChannel(
                                                  context: context,
                                                  "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk",
                                                  _numberController.text)
                                        ];
                                      }

                                      fundingSuccess = await widget
                                          .getWallet()!
                                          .fundPaymentChannel(
                                              context: context,
                                              channelDescriptors[0],
                                              "${double.parse(_numberController.text) * 1000000}");
                                      while (Navigator.canPop(context)) {
                                        Navigator.of(context).pop();
                                      }
                                    }

                                    print("fundingSuccess: " +
                                        fundingSuccess.toString());
                                    // mounted required to avoid warning
                                    // "Don't use 'BuildContext's across async gaps."
                                    if (mounted && !fundingSuccess) {
                                      await showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('Warning'),
                                              content: Text(
                                                  'Your funding request failed! '
                                                  'Please ensure your balance was '
                                                  'sufficient to fund this request.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("OK"),
                                                ),
                                              ],
                                            );
                                          });
                                    } else {
                                      await showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text('Success'),
                                              content: Text(
                                                  'Your funding request was '
                                                  'successful. Please check your '
                                                  'wallet for the status.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text("OK"),
                                                ),
                                              ],
                                            );
                                          });
                                    }
                                  } else {
                                    // Invalid input, show error message
                                    print('Invalid input');
                                  }
                                },
                        ),
                      ))),
            ],
          ),
          if (widget.getWallet() is XRPLWallet)
            TableRow(
              children: [
                TableCell(
                  child: Container(
                    margin: EdgeInsets.all(8),
                    child: Text('Memorable words:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                TableCell(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () {
                        final dataUri =
                            'data:text/plain;charset=utf-8,${(widget.getWallet() as XRPLWallet).mnemonic!}';
                        html.document.createElement('a') as html.AnchorElement
                          ..href = dataUri
                          ..download = 'dhali_xrp_wallet_secret_words.txt'
                          ..dispatchEvent(
                              html.Event.eventType('MouseEvent', 'click'));
                      },
                      child: const Icon(
                        Icons.download,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

Future<http.Response> requestSignIn() {
  final Map<String, dynamic> jsonData = {
    'txjson': {"TransactionType": "SignIn"},
    'options': {"pathfinding_fallback": false, "force_network": null},
  };

  final jsonString = jsonEncode(jsonData);
  final url =
      Uri.parse('https://kernml-xumm-3mmgxhct.uc.gateway.dev/xumm/payload');
  return http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonString,
  );
}
