import 'package:dhali_wallet/wallet_types.dart';
import 'package:flutter/foundation.dart';

abstract class DhaliWallet {
  String get address;
  ValueListenable<String?> get balance;

  Future<dynamic> getAvailableNFTs();
  Future<bool> acceptOffer(String offerIndex);
  Future<List<NFTOffer>> getNFTOffers(
    String nfTokenId,
  );
  Future<List<PaymentChannelDescriptor>> getOpenPaymentChannels(
      {String? destination_address});
  Future<PaymentChannelDescriptor> openPaymentChannel(
      String destinationAddress, String amount);
  Map<String, String> preparePayment(
      {required String destinationAddress,
      required String authAmount,
      required String channelId});
}
