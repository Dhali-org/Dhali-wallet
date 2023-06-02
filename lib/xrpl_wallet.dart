import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/wallet_types.dart';
import 'package:flutter/material.dart';
import 'dart:html';
import 'package:node_interop/util.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'package:xrpl/xrpl.dart';

// Functionality to support:
// 1. Get balance (total amount of XRP in the account) [DONE]
// 2. Send XRP to address (Open payment channel, then periodically sign &
//   send claims)
// 3. Receive XRP (periodically verify payment claims sent from Dhali)
//   (probably client sends GET request to sweep for latest available payment
//    claim, server responds with latest claim after appropriate grace period
//    has passed.  E.g. before 2 weeks has passed, returns claim from last 2
//    weeks.  After 2 weeks, new claim is returned). (Validate + submit)
// Later:
// 4. Get historical balances? [LOW PRIORITY]
// 5. New wallet (hot/cold?) (generate hash/seed/recovery words, create
//   corresponding new XRP account.  PoC => hot wallet only)

class XRPLWallet extends DhaliWallet {
  final FirebaseFirestore Function() getFirestore;
  static String uninitialisedUrl = 'NOT INITIALISED!';
  // Choose from https://xrpl.org/public-servers.html
  static String testNetUrl = 'wss://testnet.xrpl-labs.com/';
  // TODO: change once prod-ready:
  static String mainnetUrl = 'NOT IMPLEMENTED YET';

  PaymentChannelDescriptor?
      _channelDescriptor; // Must only be set in updateBalance()
  double? _toClaim; // Must only be set in updateBalance()

  String _netUrl = uninitialisedUrl;

  Wallet? _wallet;
  String? mnemonic;

  ValueNotifier<String?> _balance = ValueNotifier(null);

  XRPLWallet(String seed, {required this.getFirestore, bool testMode = false}) {
    _netUrl = testMode ? testNetUrl : mainnetUrl;
    mnemonic = seed;

    var walletFromMneomicOptions = WalletFromMnemonicOptions(
      mnemonicEncoding: "bip39",
    );

    _wallet = Wallet.fromMnemonic(seed, walletFromMneomicOptions);

    Client client = Client(_netUrl);
    var logger = Logger();

    if (_wallet == null) {
      return;
    }

    try {
      promiseToFuture(client.connect()).then((erg) {
        // TODO: Remove this in the future
        promiseToFuture(client.fundWallet(_wallet, null)).then((e) {
          String address = _wallet!.address;
          promiseToFuture(client.getXrpBalance(address)).then((balanceString) {
            updateBalance();
          }).whenComplete(() {
            client.disconnect();
          });
        });
      });
    } catch (e, stacktrace) {
      logger.e('Exception caught: ${e.toString()}');
      logger.e(stacktrace);
    }
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

  String publicKey() {
    return _wallet!.publicKey;
  }

  @override
  String get address {
    return _wallet!.address;
  }

  @override
  ValueNotifier<String?> get balance {
    return _balance;
  }

  @override
  Future<Map<String, String>> preparePayment(
      {required String destinationAddress,
      required String authAmount,
      required PaymentChannelDescriptor channelDescriptor}) async {
    return {
      "account": address,
      "destination_account": destinationAddress,
      "authorized_to_claim": authAmount,
      "signature": sendDrops(authAmount, channelDescriptor.channelId),
      "channel_id": channelDescriptor.channelId
    };
  }

  String sendDrops(String amount, String channelId) {
    return authorizeChannel(_wallet!, channelId, amount);
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
        account: _wallet!.address,
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
    Client client = Client(_netUrl);

    var logger = Logger();
    try {
      var nftOfferAccept = NFTOfferAccept(
          Account: this._wallet!.address,
          NFTokenSellOffer: offerIndex,
          TransactionType: "NFTokenAcceptOffer");
      var signTransactionOptions = SignTransactionOptions(
        autofill: true,
        failHard: true,
        wallet: _wallet!,
      );

      return promiseToFuture(client.connect()).then((_) {
        return promiseToFuture(
                client.submitAndWait(nftOfferAccept, signTransactionOptions))
            .then((response) {
          dynamic dartResponse = dartify(response);
          dynamic result = dartResponse["result"];

          return Future<bool>.value(true);
        }).catchError((e, stacktrace) {
          logger.e("Exception caught from future: $e");
          logger.e("Stack trace: $stacktrace");
          return Future<bool>.error(e);
        });
      }).catchError((e, stacktrace) {
        logger.e("Exception caught from future: $e");
        logger.e("Stack trace: $stacktrace");
        return Future<bool>.error(e);
      });
    } catch (e, stacktrace) {
      logger.e('Exception caught: $e');
      logger.e(stacktrace);
      return Future<bool>.error(e);
    } finally {
      // TODO: This looks a potential source of race conditions with the asyncronous function calls above - maybe an RAII-style wrapped class would be appropriate to use instead of doing this.
      client.disconnect();
    }
    return Future.error(ImplementationErrorException(
        "This code should never be reached, and indicates an implementation error."));
  }

  @override
  Future<List<NFTOffer>> getNFTOffers(
    String nfTokenId,
  ) async {
    Client client = Client(_netUrl);

    var logger = Logger();
    try {
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
      }).catchError((e, stacktrace) {
        logger.e("Exception caught from future: $e");
        logger.e("Stack trace: $stacktrace");
        return Future<List<NFTOffer>>.error(e);
      });
    } catch (e, stacktrace) {
      logger.e('Exception caught: $e');
      logger.e(stacktrace);
      return Future<List<NFTOffer>>.error(e);
    } finally {
      // TODO: This looks like a potential source of race conditions with the asyncronous function calls above - maybe an RAII-style wrapped class would be appropriate to use instead of doing this.
      client.disconnect();
    }
    return Future.error(ImplementationErrorException(
        "This code should never be reached, and indicates an implementation error."));
  }

  @override
  Future<List<PaymentChannelDescriptor>> getOpenPaymentChannels(
      {String? destination_address}) async {
    Client client = Client(_netUrl);

    var logger = Logger();
    try {
      var accountChannelsRequest = AccountChannelsRequest(
        account: _wallet!.address,
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

  @override
  Future<PaymentChannelDescriptor> openPaymentChannel(
      String destinationAddress, String amount) async {
    Client client = Client(_netUrl);
    var logger = Logger();

    try {
      const int settleDelay = 15768000; // 6 months
      return promiseToFuture(client.connect()).then((erg) {
        var paymentChannelCreateTransaction = PaymentChannelCreate(
          Account: _wallet!.address,
          TransactionType: "PaymentChannelCreate",
          Amount: amount,
          Destination: destinationAddress,
          SettleDelay: settleDelay,
          PublicKey: _wallet!.publicKey,
        );
        var signTransactionOptions = SignTransactionOptions(
          autofill: true,
          failHard: true,
          wallet: _wallet!,
        );

        return promiseToFuture(client.submitAndWait(
                paymentChannelCreateTransaction, signTransactionOptions))
            .then((response) {
          dynamic dartResponse = dartify(response);

          dynamic channel = dartResponse['result'];
          bool sourceAccountIsCorrect = channel["Account"] == _wallet!.address;
          bool destinationAccountIsCorrect =
              channel["Destination"] == destinationAddress;
          bool amountIsCorrect = channel["Amount"] == amount;
          bool delayIsCorrect = channel["SettleDelay"] == settleDelay;

          dynamic channelMeta = channel["meta"];
          bool transactionWasSuccessful =
              channelMeta["TransactionResult"] == "tesSUCCESS";
          bool channelIsValidated = channel["validated"] == true;
          updateBalance();

          bool channelIsValidSoFar = sourceAccountIsCorrect &&
              destinationAccountIsCorrect &&
              amountIsCorrect &&
              delayIsCorrect &&
              transactionWasSuccessful &&
              channelIsValidated;
          if (!channelIsValidSoFar) {
            var errorMessage = '''
Attempted to create invalid channel.
Valid source account: $sourceAccountIsCorrect
Destination account: $destinationAccountIsCorrect
Amount: $amountIsCorrect
Settlement delay is correct: $delayIsCorrect
Transaction was successful: $transactionWasSuccessful
Channel was validated: $channelIsValidated
                ''';
            return Future<PaymentChannelDescriptor>.error(
                InvalidPaymentChannelException(errorMessage));
          }

          dynamic affectedNodes = channelMeta["AffectedNodes"];

          const String invalidChannelId = "INVALID_CHANNEL_ID";
          String channelId = invalidChannelId;

          affectedNodes.forEach((jsAffectedNode) {
            dynamic affectedNode = jsAffectedNode;

            const String createdNodeKey = "CreatedNode";
            if (!affectedNode.containsKey(createdNodeKey)) {
              return;
            }

            dynamic createdNode = affectedNode[createdNodeKey];
            var ledgerEntryType = createdNode["LedgerEntryType"];
            if (ledgerEntryType != "PayChannel") {
              return;
            }
            channelId = createdNode["LedgerIndex"];
          });

          if (channelId == invalidChannelId) {
            return Future<PaymentChannelDescriptor>.error(
                UnexpectedResponseException(
                    "Got unexpected response: $dartResponse. It has not been handled correctly, and so needs to be investigated."));
          }
          return Future<PaymentChannelDescriptor>.value(
              PaymentChannelDescriptor(channelId, int.parse(amount)));
        }).catchError((e, stacktrace) {
          logger.e("Exception caught: $e");
          logger.e("$stacktrace");
          return Future<PaymentChannelDescriptor>.error(e);
        });
      }).catchError((e, stacktrace) {
        logger.e("Exception caught: $e");
        logger.e("$stacktrace");
        return Future<PaymentChannelDescriptor>.error(e);
      });
    } catch (e, stacktrace) {
      logger.e('Exception caught: $e');
      logger.e(stacktrace);
    } finally {
      // TODO: This looks like a potential source of race conditions with the asyncronous function calls above - maybe an RAII-style wrapped class would be appropriate to use instead of doing this.
      client.disconnect();
    }

    return Future.error(ImplementationErrorException(
        "This code should never be reached, and indicates an implementation error."));
  }

  @override
  Future<bool> fundPaymentChannel(
      PaymentChannelDescriptor descriptor, String amount) async {
    _channelDescriptor = descriptor;
    Client client = Client(_netUrl);
    var logger = Logger();

    final channelId = descriptor.channelId;
    try {
      return promiseToFuture(client.connect()).then((erg) {
        var paymentChannelCreateTransaction = PaymentChannelFund(
          Account: _wallet!.address,
          TransactionType: "PaymentChannelFund",
          Channel: channelId,
          Amount: amount,
        );
        var signTransactionOptions = SignTransactionOptions(
          autofill: true,
          failHard: true,
          wallet: _wallet!,
        );

        return promiseToFuture(client.submitAndWait(
                paymentChannelCreateTransaction, signTransactionOptions))
            .then((response) {
          dynamic dartResponse = dartify(response);

          final dynamic channel = dartResponse['result'];
          final String channelId = dartResponse['Channel'];
          final bool sourceAccountIsCorrect =
              channel["Account"] == _wallet!.address;
          final bool amountIsCorrect = channel["Amount"] == amount;

          final dynamic channelMeta = channel["meta"];
          final bool transactionWasSuccessful =
              channelMeta["TransactionResult"] == "tesSUCCESS";
          final bool channelIsValidated = channel["validated"] == true;

          final bool channelIsValidSoFar = sourceAccountIsCorrect &&
              amountIsCorrect &&
              transactionWasSuccessful &&
              channelIsValidated;
          if (!channelIsValidSoFar) {
            var errorMessage = '''
Invalid attempt to fund payment channel: $channelId.
Valid source account: $sourceAccountIsCorrect
Amount: $amountIsCorrect
Transaction was successful: $transactionWasSuccessful
Channel was validated: $channelIsValidated
                ''';
            return Future<bool>.error(
                InvalidPaymentChannelException(errorMessage));
          }

          dynamic affectedNodes = channelMeta["AffectedNodes"];

          bool found_channel = false;
          affectedNodes.forEach((jsAffectedNode) {
            dynamic affectedNode = jsAffectedNode;

            const String modifiedNodeKey = "modifiedNode";
            if (!affectedNode.containsKey(modifiedNodeKey)) {
              return;
            }

            dynamic modifiedNode = affectedNode[modifiedNodeKey];
            final ledgerEntryType = modifiedNode["LedgerEntryType"];
            final currentChannelId = modifiedNode["LedgerIndex"];
            if (ledgerEntryType != "PayChannel" ||
                currentChannelId != channelId) {
              return;
            }
            found_channel = true;
          });

          if (!found_channel) {
            return Future<bool>.error(
                "Requested channel ID was not found in 'FundPaymentChannel' result.");
          }

          updateBalance();

          return Future<bool>.value(true);
        }).catchError((e, stacktrace) {
          logger.e("Exception caught: $e");
          logger.e("$stacktrace");
          return Future<bool>.error(e);
        });
      }).catchError((e, stacktrace) {
        logger.e("Exception caught: $e");
        logger.e("$stacktrace");
        return Future<bool>.error(e);
      });
    } catch (e, stacktrace) {
      logger.e('Exception caught: $e');
      logger.e(stacktrace);
    } finally {
      // TODO: This looks like a potential source of race conditions with the asyncronous function calls above - maybe an RAII-style wrapped class would be appropriate to use instead of doing this.
      client.disconnect();
    }

    return Future.error(ImplementationErrorException(
        "This code should never be reached, and indicates an implementation error."));
  }
}
