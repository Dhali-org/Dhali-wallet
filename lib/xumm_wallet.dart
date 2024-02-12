import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/wallet_types.dart';
import 'package:dhali_wallet/widgets/buttons.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'dart:html';
import 'package:node_interop/util.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'package:xrpl/xrpl.dart';

class SignatureClaimPair {
  String signature;
  int amount;

  SignatureClaimPair(this.signature, this.amount);
}

Future<void> _showModalFromURL(String title, BuildContext? context,
    Map<String, dynamic> data, bool? isDesktop) async {
  final pngUrl = data["refs"]["qr_png"];
  final response = await http.get(Uri.parse(pngUrl));
  double fontSize = isDesktop == true ? 20.0 : 12.0;
  double padding = isDesktop == true ? 20.0 : 5.0;
  double verticalInsetPadding = isDesktop == true ? 24.0 : 5.0; // 24 is default
  double horizontalInsetPadding =
      isDesktop == true ? 40.0 : 5.0; // 40 is default

  if (context != null && response.statusCode == 200) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
              vertical: verticalInsetPadding,
              horizontal: horizontalInsetPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
                Radius.circular(20.0)), // Set your desired border radius here
          ),
          title: Text(
            title,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
          ),
          contentPadding: EdgeInsets.all(padding),
          actionsAlignment: MainAxisAlignment.center,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Open XUMM wallet on your mobile phone and scan this QR code or"
                " click \"Open XUMM\".",
                softWrap: true,
                style: TextStyle(
                  fontSize: fontSize,
                ),
              ),
              Image.memory(
                response.bodyBytes,
                width: 300,
                height: 300,
              )
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsets.all(
                  padding), // Adjust this value to your preference
              child:
                  getTextButton('Open XUMM', textSize: fontSize, onPressed: () {
                final Uri _url = Uri.parse(data["next"]["always"]);
                launchUrl(_url, mode: LaunchMode.externalApplication);
              }),
            ),
          ],
        );
      },
    );
  } else {
    print('Failed to load the image from the URL');
  }
}

void displayQRCodeFrom(
    String title, BuildContext? context, Map<String, dynamic> data,
    {bool? isDesktop}) {
  _showModalFromURL(title, context, data, isDesktop);
}

class XummWallet extends DhaliWallet {
  final FirebaseFirestore Function() getFirestore;
  static String uninitialisedUrl = 'NOT INITIALISED!';
  // Choose from https://xrpl.org/public-servers.html
  static String testNetUrl = 'wss://s.altnet.rippletest.net/';
  // TODO: change once prod-ready:
  static String mainnetUrl = 'wss://xrplcluster.com/';

  String _netUrl = uninitialisedUrl;

  String _address;

  SignatureClaimPair? _sigClaimPair;

  PaymentChannelDescriptor?
      _channelDescriptor; // Must only be set in updateBalance()
  double? _toClaim; // Must only be set in updateBalance()

  ValueNotifier<String?> _balance = ValueNotifier(null);
  ValueNotifier<String?> _amount = ValueNotifier(null);
  final bool _isDesktop;

  XummWallet(String address,
      {required this.getFirestore, bool testMode = false, bool? isDesktop})
      : _address = address,
        _isDesktop = isDesktop ?? true {
    _netUrl = testMode ? testNetUrl : mainnetUrl;
    Client client = Client(_netUrl);
    var logger = Logger();

    try {
      updateBalance();
    } catch (e, stacktrace) {
      _amount.value = "0";
      _balance.value = "0";
      logger.e('Exception caught: ${e.toString()}');
      logger.e(stacktrace);
    }
  }

  String publicKey() {
    return _address;
  }

  Future<void> updateBalance() async {
    getOpenPaymentChannels(
            destination_address: "rhtfMhppuk5siMi8jvkencnCTyjciArCh7")
        .then((paymentChannels) {
      if (paymentChannels.isNotEmpty && _channelDescriptor == null) {
        _channelDescriptor = paymentChannels[0];
        var doc_id =
            Uuid().v5(Uuid.NAMESPACE_URL, _channelDescriptor!.channelId);

        getFirestore()
            .collection("public_claim_info")
            .doc(doc_id)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            _toClaim = snapshot.data()!["to_claim"] as double;
            _balance.value = _toClaim!.toString();
          } else {
            _balance.value = "0";
          }
          _amount.value = _channelDescriptor!.amount.toString();
        });
      } else if (paymentChannels.isNotEmpty) {
        _channelDescriptor = paymentChannels[0];
        _balance.value = (_toClaim == null ? 0 : _toClaim!).toString();
        _amount.value = _channelDescriptor!.amount.toString();
      } else {
        _balance.value = "0";
        _amount.value = "0";
      }
    });
  }

  @override
  String get address {
    return _address;
  }

  @override
  ValueNotifier<String?> get balance {
    return _balance;
  }

  @override
  ValueNotifier<String?> get amount {
    return _amount;
  }

  @override
  Future<bool> fundPaymentChannel(
      PaymentChannelDescriptor descriptor, String amount,
      {required BuildContext? context}) async {
    var logger = Logger();
    try {
      http.Response response = await XummRequest({
        "TransactionType": "PaymentChannelFund",
        "Channel": descriptor.channelId,
        "Amount": amount,
      }, null);
      if (response.statusCode != 200) {
        return false;
      }
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      displayQRCodeFrom("Scan to fund your balance", context, data,
          isDesktop: _isDesktop);
      bool result =
          await poll(data["uuid"], onSuccess: (http.Response response) {
        if (context != null) {
          Navigator.pop(context);
        }
        logger.d("fundingPaymentChannel.onSuccess", response.body);
        updateBalance();
        return true;
      }, onError: (http.Response response) {
        logger.d("fundingPaymentChannel.onError");
        return false;
      }, onTimeout: () {
        logger.d("fundingPaymentChannel.onTimeout");
        return false;
      });
      return result;
    } catch (e) {
      logger.d("fundingPaymentChannel.catch");
      return false;
    }
  }

  @override
  Future<Map<String, String>> preparePayment(
      {required String destinationAddress,
      required String authAmount,
      required PaymentChannelDescriptor channelDescriptor,
      required BuildContext? context}) async {
    if (_sigClaimPair == null ||
        _sigClaimPair!.amount < int.parse(authAmount)) {
      http.Response response = await XummRequest({
        "TransactionType": "PaymentChannelAuthorize",
        "Channel": channelDescriptor.channelId,
        "Amount": authAmount
      }, null);
      if (response.statusCode != 200) {
        throw HttpException("XUMM api rejected request");
      }
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      displayQRCodeFrom("Scan to make payment", context, data,
          isDesktop: _isDesktop);
      return await poll(data["uuid"], onSuccess: (http.Response response) {
        if (context != null) {
          Navigator.pop(context);
        }
        Map<String, dynamic> body = jsonDecode(response.body);
        _sigClaimPair =
            SignatureClaimPair(body["response"]["hex"], int.parse(authAmount));
        return {
          "account": address,
          "destination_account": destinationAddress,
          "authorized_to_claim": authAmount,
          "signature": _sigClaimPair!.signature,
          "channel_id": channelDescriptor.channelId
        };
      }, onError: (http.Response response) {
        throw ClaimSigningException("Xumm failed to sign payment claim");
      }, onTimeout: () {
        throw ClaimSigningException("Xumm failed to sign payment claim");
      });
    }
    return {
      "account": address,
      "destination_account": destinationAddress,
      "authorized_to_claim": _sigClaimPair!.amount.toString(),
      "signature": _sigClaimPair!.signature,
      "channel_id": channelDescriptor.channelId
    };
  }

  Future<dynamic> submitRequest(BaseRequest request, Client client) async {
    return promiseToFuture(client.connect()).then((_) {
      return promiseToFuture(client.request(request)).then((response) {
        dynamic dartResponse = dartify(response);
        return dartResponse;
      });
    }).whenComplete(() {
      var logger = Logger();
      logger.d("Xumm.submitRequest");
      client.disconnect();
    }).catchError((e, stacktrace) {
      var logger = Logger();
      logger.e("Exception caught from future: $e");
      logger.e("Stack trace: $stacktrace");
      return Future<dynamic>.error(e);
    });
  }

  @override
  Future<dynamic> getAvailableNFTs() async {
    Client client = Client(_netUrl);
    try {
      var accountNFTsRequest = AccountNFTsRequest(
        account: _address,
        command: "account_nfts",
      );
      return submitRequest(accountNFTsRequest, client);
    } catch (e, stacktrace) {
      var logger = Logger();
      logger.e('Exception caught: $e');
      logger.e(stacktrace);
      return Future<List<PaymentChannelDescriptor>>.error(e);
    }
    return Future.error(ImplementationErrorException(
        "This code should never be reached, and indicates an implementation error."));
  }

  @override
  Future<bool> acceptOffer(String offerIndex,
      {required BuildContext? context}) async {
    http.Response response = await XummRequest({
      "TransactionType": "NFTokenAcceptOffer",
      "NFTokenSellOffer": offerIndex,
      "Account": address
    }, null);
    var data = jsonDecode(response.body) as Map<String, dynamic>;
    displayQRCodeFrom("Scan to accept NFT", context, data,
        isDesktop: _isDesktop);
    await poll(data["uuid"],
        onSuccess: (http.Response response) => {
              if (context != null) {Navigator.pop(context)}
            },
        onError: (http.Response response) => {},
        onTimeout: () => {});

    if (response.statusCode != 200) {
      throw HttpException("XUMM api rejected request");
    } else {
      return true;
    }
  }

  @override
  Future<List<NFTOffer>> getNFTOffers(
    String nfTokenId,
  ) async {
    Client client = Client(_netUrl);

    var logger = Logger();

    var nftSellOffersRequest =
        NFTSellOffersRequest(command: "nft_sell_offers", nft_id: nfTokenId);

    return promiseToFuture(client.connect()).then((_) {
      return promiseToFuture(client.request(nftSellOffersRequest))
          .then((response) {
        dynamic dartResponse = dartify(response);
        dynamic result = dartResponse["result"];

        // Confirm that it's the correct NFTokenId:
        if (result["nft_id"] != nfTokenId) {
          return Future<List<NFTOffer>>.error(
              "Unexpected NFToken ID received: \"${result['nft_id']}\" when querying for offers for \"nfTokenId\".");
        }

        List<NFTOffer> offers = [];
        dynamic responseOffers = result["offers"];
        responseOffers.forEach((offer) {
          offers.add(NFTOffer(int.parse(offer["amount"]), offer["owner"],
              offer["destination"], offer["nft_offer_index"]));
        });
        return Future<List<NFTOffer>>.value(offers);
      }).catchError((e, stacktrace) {
        logger.e("Exception caught from future: $e");
        logger.e("Stack trace: $stacktrace");
        return Future<List<NFTOffer>>.error(e);
      });
    }).whenComplete(() {
      var logger = Logger();
      logger.d("Xumm.getNFTOffers");
      client.disconnect();
    }).catchError((e, stacktrace) {
      logger.e("Exception caught from future: $e");
      logger.e("Stack trace: $stacktrace");
      return Future<List<NFTOffer>>.error(e);
    });
  }

  @override
  Future<PaymentChannelDescriptor> openPaymentChannel(
      String destinationAddress, String amount,
      {required BuildContext? context}) async {
    // This method is implemented such that it can never open more than one
    // payment channel to the same destination address
    var paymentChannel =
        await getOpenPaymentChannels(destination_address: destinationAddress);
    if (paymentChannel.isEmpty) {
      var response = await XummRequest({
        "TransactionType": "PaymentChannelCreate",
        "Amount": amount,
        "Destination": destinationAddress,
        "SettleDelay": 1209600
      }, null);
      if (response.statusCode != 200) {
        throw HttpException("XUMM api rejected request");
      }
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      displayQRCodeFrom("Scan to open a payment channel", context, data,
          isDesktop: _isDesktop);
      await poll(data["uuid"],
          onSuccess: (http.Response response) => {
                if (context != null) {Navigator.pop(context)}
              },
          onError: (http.Response response) => {},
          onTimeout: () => {});
      paymentChannel =
          await getOpenPaymentChannels(destination_address: destinationAddress);
    }
    return paymentChannel[0];
  }

  @override
  Future<List<PaymentChannelDescriptor>> getOpenPaymentChannels(
      {String? destination_address}) async {
    Client client = Client(_netUrl);

    var logger = Logger();
    try {
      var accountChannelsRequest = AccountChannelsRequest(
        account: _address,
        command: "account_channels",
        destination_account: destination_address,
      );

      return promiseToFuture(client.connect()).then((_) {
        return promiseToFuture(client.request(accountChannelsRequest))
            .then((response) {
          dynamic dartResponse = dartify(response);
          dynamic returnedChannelDescriptors =
              dartResponse["result"]["channels"];

          var channelDescriptors = <PaymentChannelDescriptor>[];
          returnedChannelDescriptors.forEach((returnedDescriptor) {
            dynamic dartDescriptor = returnedDescriptor;
            channelDescriptors.add(PaymentChannelDescriptor(
                returnedDescriptor["channel_id"],
                int.parse(returnedDescriptor["amount"])));
          });
          return Future<List<PaymentChannelDescriptor>>.value(
              channelDescriptors);
        }).catchError((e, stacktrace) {
          logger.e("Exception caught from future: $e");
          logger.e("Stack trace: $stacktrace");
          return Future<List<PaymentChannelDescriptor>>.error(e);
        });
      }).whenComplete(() {
        var logger = Logger();
        logger.d("Xumm.getOpenPaymentChannels");
        client.disconnect();
      }).catchError((e, stacktrace) {
        logger.e("Exception caught from future: $e");
        logger.e("Stack trace: $stacktrace");
        return Future<List<PaymentChannelDescriptor>>.error(e);
      });
    } catch (e, stacktrace) {
      logger.e('Exception caught: $e');
      logger.e(stacktrace);
      return Future<List<PaymentChannelDescriptor>>.error(e);
    }
    return Future.error(ImplementationErrorException(
        "This code should never be reached, and indicates an implementation error."));
  }

  Future<http.Response> XummRequest(
      Map<String, dynamic> tx_json, Map<String, dynamic>? options) async {
    final Map<String, dynamic> jsonData = {
      'txjson': tx_json,
      'options': options,
    };

    final jsonString = jsonEncode(jsonData);
    final url =
        Uri.parse('https://kernml-xumm-3mmgxhct.uc.gateway.dev/xumm/payload');
    http.Response response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonString,
    );
    return response;
  }
}

Future<dynamic> poll(String uuid,
    {required dynamic Function(http.Response) onSuccess,
    required dynamic Function(http.Response) onError,
    required dynamic Function() onTimeout}) async {
  const int pollForSeconds = 120;

  const int pollPeriodSeconds = 5;

  for (int i = 0; i < pollForSeconds; ++i) {
    await Future.delayed(const Duration(seconds: 1));
    if (i % pollPeriodSeconds == 0) {
      final url = Uri.parse(
          'https://kernml-xumm-3mmgxhct.uc.gateway.dev/xumm/payload/$uuid');
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        if (jsonDecode(response.body)["meta"]["signed"]) {
          return onSuccess(response);
        }
      } else {
        return onError(response);
      }
    }
  }
  return onTimeout();
}
