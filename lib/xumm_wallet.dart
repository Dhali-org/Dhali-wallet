import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/wallet_types.dart';
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

class XummWallet extends DhaliWallet {
  final FirebaseFirestore Function() getFirestore;
  static String uninitialisedUrl = 'NOT INITIALISED!';
  // Choose from https://xrpl.org/public-servers.html
  static String testNetUrl = 'wss://s.altnet.rippletest.net/';
  // TODO: change once prod-ready:
  static String mainnetUrl = 'NOT IMPLEMENTED YET';

  String _netUrl = uninitialisedUrl;

  String _address;

  SignatureClaimPair? _sigClaimPair;

  PaymentChannelDescriptor?
      _channelDescriptor; // Must only be set in updateBalance()
  double? _toClaim; // Must only be set in updateBalance()

  ValueNotifier<String?> _balance = ValueNotifier(null);

  XummWallet(String address,
      {required this.getFirestore, bool testMode = false})
      : _address = address {
    _netUrl = testMode ? testNetUrl : mainnetUrl;
    Client client = Client(_netUrl);
    var logger = Logger();

    try {
      updateBalance();
    } catch (e, stacktrace) {
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
            destination_address: "rstbSTpPcyxMsiXwkBxS9tFTrg2JsDNxWk")
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
            _balance.value =
                (_channelDescriptor!.amount - _toClaim!).toString();
          } else {
            _balance.value = _channelDescriptor!.amount.toString();
          }
        });
      } else if (paymentChannels.isNotEmpty) {
        _channelDescriptor = paymentChannels[0];
        _balance.value =
            (_channelDescriptor!.amount - (_toClaim == null ? 0 : _toClaim!))
                .toString();
      } else {
        _balance.value = "0";
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
  Future<bool> fundPaymentChannel(
      PaymentChannelDescriptor descriptor, String amount) async {
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
      final Uri _url = Uri.parse(data["next"]["always"]);
      launchUrl(_url, mode: LaunchMode.externalApplication);
      bool result =
          await poll(data["uuid"], onSuccess: (http.Response response) {
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
      required PaymentChannelDescriptor channelDescriptor}) async {
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
      final Uri _url = Uri.parse(data["next"]["always"]);
      launchUrl(_url, mode: LaunchMode.externalApplication);
      return await poll(data["uuid"], onSuccess: (http.Response response) {
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
      }).catchError((e, stacktrace) {
        var logger = Logger();
        logger.e("Exception caught from future: $e");
        logger.e("Stack trace: $stacktrace");
        return Future<dynamic>.error(e);
      });
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
    } finally {
      // TODO: This looks like the source of race conditions with the asyncronous function calls above - maybe an RAII-style wrapped class would be appropriate to use instead of doing this.
      client.disconnect();
    }
    return Future.error(ImplementationErrorException(
        "This code should never be reached, and indicates an implementation error."));
  }

  @override
  Future<bool> acceptOffer(String offerIndex) async {
    return false;
  }

  @override
  Future<List<NFTOffer>> getNFTOffers(
    String nfTokenId,
  ) async {
    return [];
  }

  @override
  Future<PaymentChannelDescriptor> openPaymentChannel(
      String destinationAddress, String amount) async {
    // This method is implemented such that it can never open more than one
    // payment channel to the same destination address
    var paymentChannel =
        await getOpenPaymentChannels(destination_address: destinationAddress);
    if (paymentChannel.isEmpty) {
      var response = await XummRequest({
        "TransactionType": "PaymentChannelCreate",
        "Amount": amount,
        "Destination": destinationAddress,
        "SettleDelay": 15768000
      }, null);
      if (response.statusCode != 200) {
        throw HttpException("XUMM api rejected request");
      }
      var data = jsonDecode(response.body) as Map<String, dynamic>;
      final Uri _url = Uri.parse(data["next"]["always"]);
      launchUrl(_url, mode: LaunchMode.externalApplication);
      await poll(data["uuid"],
          onSuccess: (http.Response response) {
            updateBalance();
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

          updateBalance();

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
      });
    } catch (e, stacktrace) {
      logger.e('Exception caught: $e');
      logger.e(stacktrace);
      return Future<List<PaymentChannelDescriptor>>.error(e);
    } finally {
      // TODO: This looks like a potential source of race conditions with the asyncronous function calls above - maybe an RAII-style wrapped class would be appropriate to use instead of doing this.
      client.disconnect();
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
