import 'package:dhali_wallet/wallet_types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImplementationErrorException implements Exception {
  String message;
  ImplementationErrorException(this.message);
}

class UnexpectedResponseException implements Exception {
  String message;
  UnexpectedResponseException(this.message);
}

class InvalidPaymentChannelException implements Exception {
  String message;
  InvalidPaymentChannelException(this.message);
}

class ChannelFundingException implements Exception {
  String message;
  ChannelFundingException(this.message);
}

class ClaimSigningException implements Exception {
  String message;
  ClaimSigningException(this.message);
}

abstract class DhaliWallet {
  String get address;

  // The balance is the total value that has been used already from the channel
  ValueListenable<String?> get balance;

  // The amounnt is the total that has been deposited into the channel
  ValueListenable<String?> get amount;

  Future<dynamic> getAvailableNFTs();
  Future<bool> acceptOffer(String offerIndex, {required BuildContext? context});
  Future<List<NFTOffer>> getNFTOffers(
    String nfTokenId,
  );

  Future<bool> fundPaymentChannel(
      PaymentChannelDescriptor descriptor, String amount,
      {required BuildContext? context});

  Future<List<PaymentChannelDescriptor>> getOpenPaymentChannels(
      {String? destination_address});

  Future<PaymentChannelDescriptor> openPaymentChannel(
      String destinationAddress, String amount,
      {required BuildContext? context});

  Future<Map<String, String>> preparePayment(
      {required String destinationAddress,
      required String authAmount,
      required PaymentChannelDescriptor channelDescriptor,
      required BuildContext? context});
}
