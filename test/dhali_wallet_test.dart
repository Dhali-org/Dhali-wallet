import 'package:dhali_wallet/dhali_wallet.dart';
import 'package:dhali_wallet/xrpl_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late XRPLWallet? mockWallet;
  late TextTheme textTheme = TextTheme();
  group('Wallets', () {
    setUpAll(() {
      textTheme = TextTheme();
    });

    testWidgets('Navigate wallet tabs', (WidgetTester tester) async {
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
            return mockWallet;
          },
          setWallet: (XRPLWallet wallet) {
            mockWallet = wallet;
          },
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
  });
}
