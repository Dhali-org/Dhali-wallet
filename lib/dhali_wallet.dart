import 'package:dhali_wallet/wallet_types.dart';

abstract class DhaliWallet {
  String get address;
  Future<dynamic> getAvailableNFTs();
  String sendDrops(String amount, String channelId);
  Future<bool> acceptOffer(String offerIndex);
  Future<List<NFTOffer>> getNFTOffers(
    String nfTokenId,
  );
  Future<List<PaymentChannelDescriptor>> getOpenPaymentChannels(
      {String? destination_address});
  Future<PaymentChannelDescriptor> openPaymentChannel(
      String destinationAddress, String amount);
}
