// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:booto_shawarma_pos/main.dart';
import 'package:booto_shawarma_pos/providers/auth_provider.dart';
import 'package:booto_shawarma_pos/providers/menu_provider.dart';
import 'package:booto_shawarma_pos/providers/cart_provider.dart';
import 'package:booto_shawarma_pos/providers/order_provider.dart';
import 'package:booto_shawarma_pos/providers/dashboard_provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MenuProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ],
        child: const BootoShawarmaPosApp(),
      ),
    );
  });
}
