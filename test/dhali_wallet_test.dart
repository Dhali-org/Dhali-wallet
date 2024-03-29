import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/dhali_wallet_widget.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:dhali_wallet/xumm_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:html' as html;

import 'dhali_wallet_test.mocks.dart';

@GenerateMocks([XRPLWallet, XummWallet])
void main() {
  late TextTheme textTheme = TextTheme();
  group('Wallets', () {
    setUpAll(() {
      textTheme = TextTheme();
    });

    testWidgets('No active wallet', (WidgetTester tester) async {
      const w = 1480;
      const h = 1080;

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      await tester.pumpWidget(MaterialApp(
        title: "Dhali",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: textTheme,
          platform: TargetPlatform.iOS,
        ),
        home: WalletHomeScreen(
          title: "wallet",
          getWallet: () {
            return null;
          },
          setWallet: (DhaliWallet? wallet) {},
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text("Available wallets"), findsOneWidget);
      expect(find.text("Active wallet"), findsOneWidget);
      expect(find.text("You must choose a wallet "), findsNothing);
      expect(find.text(" Use free test wallet"), findsNothing);
      expect(find.text(" Link XUMM wallet"), findsOneWidget);
      expect(find.text(" Link GemWallet"), findsOneWidget);

      await tester.tap(find.text("Active wallet"));
      await tester.pumpAndSettle();
      expect(find.text("You must choose a wallet "), findsOneWidget);

      await tester.tap(find.text("Available wallets"));
      await tester.pumpAndSettle();
      expect(find.text("You must choose a wallet "), findsNothing);
    });

    testWidgets('Active raw XRPL wallet', (WidgetTester tester) async {
      const w = 1480;
      const h = 1080;
      DhaliWallet? mockWallet = MockXRPLWallet();
      when((mockWallet as MockXRPLWallet).amount)
          .thenReturn(ValueNotifier("0"));

      when((mockWallet as MockXRPLWallet).balance)
          .thenReturn(ValueNotifier("1000000"));
      when(mockWallet.address).thenReturn("a-random-address");
      when(mockWallet.mnemonic).thenReturn("some random words");

      final dpi = tester.binding.window.devicePixelRatio;
      tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

      await tester.pumpWidget(MaterialApp(
        title: "Dhali",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: textTheme,
          platform: TargetPlatform.iOS,
        ),
        home: WalletHomeScreen(
          title: "wallet",
          getWallet: () {
            return mockWallet;
          },
          setWallet: (DhaliWallet? wallet) {
            mockWallet = wallet;
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text("Available wallets"), findsOneWidget);
      expect(find.text("Active wallet"), findsOneWidget);
      expect(find.text("Choose a wallet"), findsNothing);

      expect(find.text("Show address"), findsOneWidget);
      expect(find.text("Log out"), findsOneWidget);
      expect(find.text("Total deposited:"), findsOneWidget);
      expect(find.text("Total spent:"), findsOneWidget);
      expect(find.text('1 XRP '), findsOneWidget);
      expect(find.text('0 XRP '), findsOneWidget);

      await tester.tap(find.text("Show address"));
      await tester.pumpAndSettle();
      expect(find.text("a-random-address"), findsOneWidget);
      await tester.tap(find.text("OK"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Available wallets"));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("gem_wallet_tile")));
      await tester.pumpAndSettle();
      expect(find.text('GemWallet coming soon'), findsOneWidget);
      await tester.tap(find.text("Available wallets"));
      await tester.pumpAndSettle();
    });
  });

  // TODO : Add tests for ensuring wallets are accessible in a mutually
  // exclusive manner: Activating RawXrpWallet then clicking on XummWallet
  // should not present a Xumm wallet without having to login to Xumm

  testWidgets('Active XUMM wallet', (WidgetTester tester) async {
    const w = 1480;
    const h = 1080;
    DhaliWallet? mockWallet = MockXummWallet();
    when((mockWallet as MockXummWallet).amount)
        .thenReturn(ValueNotifier("1000000"));
    when((mockWallet as MockXummWallet).balance)
        .thenReturn(ValueNotifier("2000000"));
    when(mockWallet.address).thenReturn("a-random-address");

    final dpi = tester.binding.window.devicePixelRatio;
    tester.binding.window.physicalSizeTestValue = Size(w * dpi, h * dpi);

    await tester.pumpWidget(MaterialApp(
      title: "Dhali",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: textTheme,
        platform: TargetPlatform.iOS,
      ),
      home: WalletHomeScreen(
        title: "wallet",
        getWallet: () {
          return mockWallet;
        },
        setWallet: (DhaliWallet? wallet) {
          mockWallet = wallet;
        },
      ),
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.text("Available wallets"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("xumm_wallet_tile")));
    await tester.pumpAndSettle();

    expect(find.text('Log out'), findsOneWidget);
    expect(find.text("Show address"), findsOneWidget);
    expect(find.text("Total deposited:"), findsOneWidget);
    expect(find.text("Total spent:"), findsOneWidget);
    expect(find.text('2 XRP '), findsOneWidget);
    expect(find.text('1 XRP '), findsOneWidget);

    await tester.tap(find.text("Available wallets"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("gem_wallet_tile")));
    await tester.pumpAndSettle();
    expect(find.text('GemWallet coming soon'), findsOneWidget);
    await tester.tap(find.text("Available wallets"));
    await tester.pumpAndSettle();
  });
}
