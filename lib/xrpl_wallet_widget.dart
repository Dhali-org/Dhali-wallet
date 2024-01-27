import 'dart:convert';
import 'dart:html';
import 'dart:js_interop';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali_wallet/dhali_wallet_widget.dart';
import 'package:dhali_wallet/wallet_types.dart';
import 'package:dhali_wallet/widgets/buttons.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:dhali_wallet/xumm_wallet.dart';
import 'package:flutter/foundation.dart';
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
  TextEditingController _number2Controller = TextEditingController();
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
              print(response.body);
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
              Container(height: 1, color: Colors.grey), // Divider
              Container(height: 1, color: Colors.grey),
            ],
          ),
          TableRow(
            children: [
              TableCell(
                child: Container(
                  margin: EdgeInsets.all(8),
                  child: Text('Total deposited:',
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
                        valueListenable: widget.getWallet()!.amount,
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
                                      'This is the total amount of XRP '
                                      'you have placed into your payment channel '
                                      'with Dhali.\n\n'
                                      'To spend this, you must click '
                                      '\'Authorise spending\'.'),
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
          ), // Divider row
          TableRow(
            children: [
              TableCell(
                child: Container(
                  margin: EdgeInsets.all(8),
                  child: TextFormField(
                    onChanged: (_) {
                      setState(() {});
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    controller: _numberController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'XRP',
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
                          'Deposit',
                          textSize: fontSize,
                          onPressed: _numberController.text.isEmpty &&
                                  double.tryParse(_numberController.text) != 0
                              ? null
                              : () async {
                                  bool? fundPaymentChannel = await showDialog<
                                          bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Are you sure?'),
                                          content: Text(
                                              'You are about to fund your payment channel!\n\n'
                                              'You can retrieve any unspent funds later.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, false);
                                              },
                                              child: const Text("No"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, true);
                                              },
                                              child: const Text("Yes"),
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
                                                      "rhtfMhppuk5siMi8jvkencnCTyjciArCh7");
                                      if (channelDescriptors.isEmpty) {
                                        // TODO : depend on Dhali public address
                                        channelDescriptors = [
                                          await widget
                                              .getWallet()!
                                              .openPaymentChannel(
                                                  context: context,
                                                  "rhtfMhppuk5siMi8jvkencnCTyjciArCh7",
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

          TableRow(
            children: [
              Container(height: 25, color: Colors.transparent), // Divider
              Container(height: 25, color: Colors.transparent),
            ],
          ),
          TableRow(
            children: [
              TableCell(
                child: Container(
                  margin: EdgeInsets.all(8),
                  child: Text('Total spent:',
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
                                  content:
                                      Text('This is the total amount of XRP '
                                          'you have spent through Dhali.'),
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
                    onChanged: (_) {
                      setState(() {});
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,3}')),
                    ],
                    controller: _number2Controller,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'XRP',
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
                          'Get payment claim',
                          textSize: fontSize,
                          onPressed: _number2Controller.text.isEmpty &&
                                  double.tryParse(_number2Controller.text) != 0
                              ? null
                              : () async {
                                  bool? fundPaymentChannel = await showDialog<
                                          bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Are you sure?'),
                                          content: Text(
                                              'You are about to create a payment claim.\n\n'
                                              'This will authorise Dhali to use '
                                              'some of your deposited funds.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, false);
                                              },
                                              child: const Text("No"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, true);
                                              },
                                              child: const Text("Yes"),
                                            ),
                                          ],
                                        );
                                      });
                                  if (fundPaymentChannel != null &&
                                      !fundPaymentChannel) {
                                    return;
                                  }

                                  double? number =
                                      double.tryParse(_number2Controller.text);
                                  if (number != null) {
                                    var claim;
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
                                            title:
                                                Text('Creating payment claim'),
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
                                                      "rhtfMhppuk5siMi8jvkencnCTyjciArCh7");
                                      if (channelDescriptors.isEmpty) {
                                        // TODO : depend on Dhali public address
                                        channelDescriptors = [
                                          await widget.getWallet()!.openPaymentChannel(
                                              context: context,
                                              "rhtfMhppuk5siMi8jvkencnCTyjciArCh7",
                                              "${double.parse(_number2Controller.text) * 1000000}")
                                        ];
                                      }

                                      claim = await widget.getWallet()!.preparePayment(
                                          destinationAddress:
                                              "rhtfMhppuk5siMi8jvkencnCTyjciArCh7",
                                          context: context,
                                          channelDescriptor:
                                              channelDescriptors[0],
                                          authAmount:
                                              "${double.parse(widget.getWallet()!.balance.value!) + (double.parse(_number2Controller.text)) * 1000000}");
                                      print(claim);
                                      while (Navigator.canPop(context)) {
                                        Navigator.of(context).pop();
                                      }
                                    }

                                    // mounted required to avoid warning
                                    // "Don't use 'BuildContext's across async gaps."
                                    if (mounted &&
                                        claim.toString().isNotEmpty) {
                                      await showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              content: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text('Success!',
                                                      style: TextStyle(
                                                          fontSize: 25.0)),
                                                  Text(
                                                      'Here is your payment claim. Please take a copy:\n\n',
                                                      style: TextStyle(
                                                          fontSize: 16.0)),
                                                  Container(
                                                    padding: EdgeInsets.all(
                                                        8.0), // Add some padding
                                                    decoration: BoxDecoration(
                                                        color: Colors.grey[
                                                            850], // Light grey background
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                8.0), // Grey border,
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey[200]!)),
                                                    child: SelectableText(
                                                      jsonEncode(claim),
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'Courier', // Monospaced font
                                                          fontSize: 12.0,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                  Text('\n\nExample usage:\n',
                                                      style: TextStyle(
                                                          fontSize: 16.0)),
                                                  Container(
                                                      padding: EdgeInsets.all(
                                                          8.0), // Add some padding
                                                      decoration: BoxDecoration(
                                                          color: Colors.grey[
                                                              850], // Light grey background
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          border: Border.all(
                                                              color: Colors
                                                                      .grey[
                                                                  200]!) // Grey border
                                                          ),
                                                      child: SelectableText(
                                                        '\$ PAYMENT_CLAIM=\'${jsonEncode(claim)}\''
                                                        '\n\n'
                                                        '\$ curl -H "Payment-Claim: \$PAYMENT_CLAIM" https://run.api.dhali.io/de3e1aa49-575a-488a-999e-d287c14c2c60/api/v1/xls20-nfts/all/issuers',
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'Courier', // Monospaced font
                                                            fontSize: 12.0,
                                                            color:
                                                                Colors.white),
                                                      ))
                                                ],
                                              ),
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
                Container(height: 25, color: Colors.transparent), // Divider
                Container(height: 25, color: Colors.transparent),
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
