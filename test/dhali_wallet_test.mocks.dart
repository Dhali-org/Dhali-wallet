// Mocks generated by Mockito 5.4.1 from annotations
// in dhali_wallet/test/dhali_wallet_test.dart.
// Do not manually edit this file.

// @dart=2.19

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i7;

import 'package:cloud_firestore/cloud_firestore.dart' as _i2;
import 'package:dhali_wallet/wallet_types.dart' as _i4;
import 'package:dhali_wallet/xrpl_wallet.dart' as _i6;
import 'package:dhali_wallet/xumm_wallet.dart' as _i9;
import 'package:flutter/material.dart' as _i3;
import 'package:http/http.dart' as _i5;
import 'package:mockito/mockito.dart' as _i1;
import 'package:xrpl/xrpl.dart' as _i8;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeFirebaseFirestore_0 extends _i1.SmartFake
    implements _i2.FirebaseFirestore {
  _FakeFirebaseFirestore_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeValueNotifier_1<T> extends _i1.SmartFake
    implements _i3.ValueNotifier<T> {
  _FakeValueNotifier_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePaymentChannelDescriptor_2 extends _i1.SmartFake
    implements _i4.PaymentChannelDescriptor {
  _FakePaymentChannelDescriptor_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeResponse_3 extends _i1.SmartFake implements _i5.Response {
  _FakeResponse_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [XRPLWallet].
///
/// See the documentation for Mockito's code generation for more information.
class MockXRPLWallet extends _i1.Mock implements _i6.XRPLWallet {
  MockXRPLWallet() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.FirebaseFirestore Function() get getFirestore => (super.noSuchMethod(
        Invocation.getter(#getFirestore),
        returnValue: () => _FakeFirebaseFirestore_0(
          this,
          Invocation.getter(#getFirestore),
        ),
      ) as _i2.FirebaseFirestore Function());
  @override
  set mnemonic(String? _mnemonic) => super.noSuchMethod(
        Invocation.setter(
          #mnemonic,
          _mnemonic,
        ),
        returnValueForMissingStub: null,
      );
  @override
  String get address => (super.noSuchMethod(
        Invocation.getter(#address),
        returnValue: '',
      ) as String);
  @override
  _i3.ValueNotifier<String?> get balance => (super.noSuchMethod(
        Invocation.getter(#balance),
        returnValue: _FakeValueNotifier_1<String?>(
          this,
          Invocation.getter(#balance),
        ),
      ) as _i3.ValueNotifier<String?>);
  @override
  _i3.ValueNotifier<String?> get amount => (super.noSuchMethod(
        Invocation.getter(#amount),
        returnValue: _FakeValueNotifier_1<String?>(
          this,
          Invocation.getter(#amount),
        ),
      ) as _i3.ValueNotifier<String?>);
  @override
  _i7.Future<void> updateBalance() => (super.noSuchMethod(
        Invocation.method(
          #updateBalance,
          [],
        ),
        returnValue: _i7.Future<void>.value(),
        returnValueForMissingStub: _i7.Future<void>.value(),
      ) as _i7.Future<void>);
  @override
  String publicKey() => (super.noSuchMethod(
        Invocation.method(
          #publicKey,
          [],
        ),
        returnValue: '',
      ) as String);
  @override
  _i7.Future<Map<String, String>> preparePayment({
    required String? destinationAddress,
    required String? authAmount,
    required _i4.PaymentChannelDescriptor? channelDescriptor,
    required _i3.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #preparePayment,
          [],
          {
            #destinationAddress: destinationAddress,
            #authAmount: authAmount,
            #channelDescriptor: channelDescriptor,
            #context: context,
          },
        ),
        returnValue: _i7.Future<Map<String, String>>.value(<String, String>{}),
      ) as _i7.Future<Map<String, String>>);
  @override
  String sendDrops(
    String? amount,
    String? channelId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #sendDrops,
          [
            amount,
            channelId,
          ],
        ),
        returnValue: '',
      ) as String);
  @override
  _i7.Future<dynamic> submitRequest(
    _i8.BaseRequest? request,
    _i8.Client? client,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #submitRequest,
          [
            request,
            client,
          ],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  _i7.Future<dynamic> getAvailableNFTs() => (super.noSuchMethod(
        Invocation.method(
          #getAvailableNFTs,
          [],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  _i7.Future<bool> acceptOffer(
    String? offerIndex, {
    required _i3.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #acceptOffer,
          [offerIndex],
          {#context: context},
        ),
        returnValue: _i7.Future<bool>.value(false),
      ) as _i7.Future<bool>);
  @override
  _i7.Future<List<_i4.NFTOffer>> getNFTOffers(String? nfTokenId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getNFTOffers,
          [nfTokenId],
        ),
        returnValue: _i7.Future<List<_i4.NFTOffer>>.value(<_i4.NFTOffer>[]),
      ) as _i7.Future<List<_i4.NFTOffer>>);
  @override
  _i7.Future<List<_i4.PaymentChannelDescriptor>> getOpenPaymentChannels(
          {String? destination_address}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getOpenPaymentChannels,
          [],
          {#destination_address: destination_address},
        ),
        returnValue: _i7.Future<List<_i4.PaymentChannelDescriptor>>.value(
            <_i4.PaymentChannelDescriptor>[]),
      ) as _i7.Future<List<_i4.PaymentChannelDescriptor>>);
  @override
  _i7.Future<_i4.PaymentChannelDescriptor> openPaymentChannel(
    String? destinationAddress,
    String? amount, {
    required _i3.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #openPaymentChannel,
          [
            destinationAddress,
            amount,
          ],
          {#context: context},
        ),
        returnValue: _i7.Future<_i4.PaymentChannelDescriptor>.value(
            _FakePaymentChannelDescriptor_2(
          this,
          Invocation.method(
            #openPaymentChannel,
            [
              destinationAddress,
              amount,
            ],
            {#context: context},
          ),
        )),
      ) as _i7.Future<_i4.PaymentChannelDescriptor>);
  @override
  _i7.Future<bool> fundPaymentChannel(
    _i4.PaymentChannelDescriptor? descriptor,
    String? amount, {
    required _i3.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #fundPaymentChannel,
          [
            descriptor,
            amount,
          ],
          {#context: context},
        ),
        returnValue: _i7.Future<bool>.value(false),
      ) as _i7.Future<bool>);
}

/// A class which mocks [XummWallet].
///
/// See the documentation for Mockito's code generation for more information.
class MockXummWallet extends _i1.Mock implements _i9.XummWallet {
  MockXummWallet() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.FirebaseFirestore Function() get getFirestore => (super.noSuchMethod(
        Invocation.getter(#getFirestore),
        returnValue: () => _FakeFirebaseFirestore_0(
          this,
          Invocation.getter(#getFirestore),
        ),
      ) as _i2.FirebaseFirestore Function());
  @override
  String get address => (super.noSuchMethod(
        Invocation.getter(#address),
        returnValue: '',
      ) as String);
  @override
  _i3.ValueNotifier<String?> get balance => (super.noSuchMethod(
        Invocation.getter(#balance),
        returnValue: _FakeValueNotifier_1<String?>(
          this,
          Invocation.getter(#balance),
        ),
      ) as _i3.ValueNotifier<String?>);
  @override
  _i3.ValueNotifier<String?> get amount => (super.noSuchMethod(
        Invocation.getter(#amount),
        returnValue: _FakeValueNotifier_1<String?>(
          this,
          Invocation.getter(#amount),
        ),
      ) as _i3.ValueNotifier<String?>);
  @override
  String publicKey() => (super.noSuchMethod(
        Invocation.method(
          #publicKey,
          [],
        ),
        returnValue: '',
      ) as String);
  @override
  _i7.Future<void> updateBalance() => (super.noSuchMethod(
        Invocation.method(
          #updateBalance,
          [],
        ),
        returnValue: _i7.Future<void>.value(),
        returnValueForMissingStub: _i7.Future<void>.value(),
      ) as _i7.Future<void>);
  @override
  _i7.Future<bool> fundPaymentChannel(
    _i4.PaymentChannelDescriptor? descriptor,
    String? amount, {
    required _i3.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #fundPaymentChannel,
          [
            descriptor,
            amount,
          ],
          {#context: context},
        ),
        returnValue: _i7.Future<bool>.value(false),
      ) as _i7.Future<bool>);
  @override
  _i7.Future<Map<String, String>> preparePayment({
    required String? destinationAddress,
    required String? authAmount,
    required _i4.PaymentChannelDescriptor? channelDescriptor,
    required _i3.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #preparePayment,
          [],
          {
            #destinationAddress: destinationAddress,
            #authAmount: authAmount,
            #channelDescriptor: channelDescriptor,
            #context: context,
          },
        ),
        returnValue: _i7.Future<Map<String, String>>.value(<String, String>{}),
      ) as _i7.Future<Map<String, String>>);
  @override
  _i7.Future<dynamic> submitRequest(
    _i8.BaseRequest? request,
    _i8.Client? client,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #submitRequest,
          [
            request,
            client,
          ],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  _i7.Future<dynamic> getAvailableNFTs() => (super.noSuchMethod(
        Invocation.method(
          #getAvailableNFTs,
          [],
        ),
        returnValue: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);
  @override
  _i7.Future<bool> acceptOffer(
    String? offerIndex, {
    required _i3.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #acceptOffer,
          [offerIndex],
          {#context: context},
        ),
        returnValue: _i7.Future<bool>.value(false),
      ) as _i7.Future<bool>);
  @override
  _i7.Future<List<_i4.NFTOffer>> getNFTOffers(String? nfTokenId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getNFTOffers,
          [nfTokenId],
        ),
        returnValue: _i7.Future<List<_i4.NFTOffer>>.value(<_i4.NFTOffer>[]),
      ) as _i7.Future<List<_i4.NFTOffer>>);
  @override
  _i7.Future<_i4.PaymentChannelDescriptor> openPaymentChannel(
    String? destinationAddress,
    String? amount, {
    required _i3.BuildContext? context,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #openPaymentChannel,
          [
            destinationAddress,
            amount,
          ],
          {#context: context},
        ),
        returnValue: _i7.Future<_i4.PaymentChannelDescriptor>.value(
            _FakePaymentChannelDescriptor_2(
          this,
          Invocation.method(
            #openPaymentChannel,
            [
              destinationAddress,
              amount,
            ],
            {#context: context},
          ),
        )),
      ) as _i7.Future<_i4.PaymentChannelDescriptor>);
  @override
  _i7.Future<List<_i4.PaymentChannelDescriptor>> getOpenPaymentChannels(
          {String? destination_address}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getOpenPaymentChannels,
          [],
          {#destination_address: destination_address},
        ),
        returnValue: _i7.Future<List<_i4.PaymentChannelDescriptor>>.value(
            <_i4.PaymentChannelDescriptor>[]),
      ) as _i7.Future<List<_i4.PaymentChannelDescriptor>>);
  @override
  _i7.Future<_i5.Response> XummRequest(
    Map<String, dynamic>? tx_json,
    Map<String, dynamic>? options,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #XummRequest,
          [
            tx_json,
            options,
          ],
        ),
        returnValue: _i7.Future<_i5.Response>.value(_FakeResponse_3(
          this,
          Invocation.method(
            #XummRequest,
            [
              tx_json,
              options,
            ],
          ),
        )),
      ) as _i7.Future<_i5.Response>);
}
