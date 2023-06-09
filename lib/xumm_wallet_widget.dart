import 'dart:convert';
import 'dart:html';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali_wallet/wallet_types.dart';
import 'package:dhali_wallet/xumm_wallet.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class XummWalletWidget extends StatefulWidget {
  const XummWalletWidget(
      {super.key,
      required this.getWallet,
      required this.setWallet,
      required this.onActivation});

  final void Function()? onActivation;
  final DhaliWallet? Function() getWallet;
  final Function(DhaliWallet?) setWallet;

  @override
  State<XummWalletWidget> createState() => _XummWalletWidgetState();
}

class _XummWalletWidgetState extends State<XummWalletWidget> {
  double xummTimeout = 0.0;
  bool waiting = false;
  TextEditingController _numberController = TextEditingController();
  String _submittedNumber = '';
  PaymentChannelDescriptor? _descriptor;
  @override
  Widget build(BuildContext context) {
    return widget.getWallet() is XummWallet ? viewAccount() : signin();
  }

  Widget signin() {
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
          final Uri _url = Uri.parse(data["next"]["always"]);
          launchUrl(_url, mode: LaunchMode.externalApplication);
          poll(
            data["uuid"],
            onSuccess: (http.Response response) {
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
          return const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Opening popup...\n\nPlease ensure this isn't blocked; then scan the QR code  ",
                  style: TextStyle(
                    fontSize: 25,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  width: 10,
                ),
                CircularProgressIndicator()
              ]);
        }
      },
    );
  }

  Widget viewAccount() {
    const double fontSize = 20;
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              TableCell(
                  child: Container(
                margin: EdgeInsets.all(8),
                child: const Row(
                  children: [
                    Text(
                      'Linked with XUMM ',
                      style: TextStyle(fontSize: 18),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              TableCell(
                child: Container(
                  margin: EdgeInsets.all(8),
                  child: SelectableText(widget.getWallet()!.address,
                      style: TextStyle(fontSize: 18)),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                              style: TextStyle(fontSize: 18));
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
                child: Container(
                  margin: EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () async {
                      bool? fundPaymentChannel = await showDialog<bool>(
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
                      if (fundPaymentChannel != null && !fundPaymentChannel) {
                        return;
                      }

                      double? number = double.tryParse(_numberController.text);
                      if (number != null) {
                        number *= 1000000; // Convert to drops
                        // Valid number, proceed with submission
                        List<PaymentChannelDescriptor> channelDescriptors =
                            await widget.getWallet()!.getOpenPaymentChannels(
                                destination_address:
                                    "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk");
                        if (channelDescriptors.isEmpty) {
                          // TODO : depend on Dhali public address
                          channelDescriptors = [
                            await widget.getWallet()!.openPaymentChannel(
                                "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk",
                                _numberController.text)
                          ];
                        }
                        bool fundingSuccess = await widget
                            .getWallet()!
                            .fundPaymentChannel(channelDescriptors[0],
                                "${double.parse(_numberController.text) * 1000000}");
                        print("fundingSuccess: " + fundingSuccess.toString());
                        // mounted required to avoid warning
                        // "Don't use 'BuildContext's across async gaps."
                        if (mounted && !fundingSuccess) {
                          await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Warning'),
                                  content: Text('Your funding request failed! '
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
                                  content: Text('Your funding request was '
                                      'successful. Please check your XUMM '
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
                    child: Text('Fund Dhali balance'),
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
