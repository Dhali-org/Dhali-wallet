class NFTOffer {
  final int amount;
  final String owner;
  final String destination;
  final String offerIndex;

  NFTOffer(int this.amount, String this.owner, String this.destination,
      String this.offerIndex);
}

class PaymentChannelDescriptor {
  String channelId;
  int amount;

  PaymentChannelDescriptor(this.channelId, this.amount);
}
