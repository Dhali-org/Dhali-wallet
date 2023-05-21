import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/dhali_wallet_widget.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:html' as html;

import 'dhali_wallet_test.mocks.dart';

@GenerateMocks([XRPLWallet])
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
          bodyTextColor: Color(0xFF0000FF),
          title: "wallet",
          getWallet: () {
            return null;
          },
          setWallet: (DhaliWallet wallet) {},
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text("Available wallets"), findsOneWidget);
      expect(find.text("Active wallet"), findsOneWidget);
      expect(find.text("Please select a wallet from 'Available wallets'"),
          findsNothing);

      await tester.tap(find.text("Active wallet"));
      await tester.pumpAndSettle();
      expect(find.text("Please select a wallet from 'Available wallets'"),
          findsOneWidget);

      await tester.tap(find.text("Available wallets"));
      await tester.pumpAndSettle();
      expect(find.text("Please select a wallet from 'Available wallets'"),
          findsNothing);
    });

    testWidgets('Active raw XRPL wallet', (WidgetTester tester) async {
      const w = 1480;
      const h = 1080;
      DhaliWallet mockWallet = MockXRPLWallet();
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
          bodyTextColor: Color(0xFF0000FF),
          title: "wallet",
          getWallet: () {
            return mockWallet;
          },
          setWallet: (DhaliWallet wallet) {
            mockWallet = wallet;
          },
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text("Available wallets"), findsOneWidget);
      expect(find.text("Active wallet"), findsOneWidget);
      expect(find.text("Please select a wallet from 'Available wallets'"),
          findsNothing);

      await tester.tap(find.byKey(const Key("raw_xrp_wallet_tile")));
      await tester.pumpAndSettle();

      expect(find.text('Balance: 1000000 XRP'), findsOneWidget);
      expect(find.text('Classic address: a-random-address'), findsOneWidget);
      expect(find.text('Memorable words: '), findsOneWidget);

      await tester.tap(find.text("Available wallets"));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("xumm_wallet_tile")));
      await tester.pumpAndSettle();
      expect(find.text('XUMM wallet coming soon!'), findsOneWidget);

      await tester.tap(find.text("Available wallets"));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key("fynbos_wallet_tile")));
      await tester.pumpAndSettle();
      expect(find.text('Fynbos wallet coming soon!'), findsOneWidget);
      await tester.tap(find.text("Available wallets"));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key("metamask_wallet_tile")));
      await tester.pumpAndSettle();
      expect(find.text('MetaMask wallet coming soon!'), findsOneWidget);
      await tester.tap(find.text("Available wallets"));
      await tester.pumpAndSettle();
    });
  });
}
