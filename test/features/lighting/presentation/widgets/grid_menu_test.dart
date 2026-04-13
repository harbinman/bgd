import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/grid_menu_overlay.dart';
import 'package:miaomiao_fill_light/features/lighting/presentation/widgets/grid_item.dart';

void main() {
  testWidgets('GridMenuOverlay should show Gaussian Blur and 12 items when visible', (WidgetTester tester) async {
    bool isVisible = true;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridMenuOverlay(
            isVisible: isVisible,
            onClose: () => isVisible = false,
          ),
        ),
      ),
    );

    // Initial state: Forward animation begins
    await tester.pump(const Duration(seconds: 1)); // Wait for timer or fade
    await tester.pumpAndSettle(); // Wait for all animations to finish

    // 1. Verify 12 grid items exist
    expect(find.byType(GridItem, skipOffstage: false), findsNWidgets(12));

    // 2. Verify titles exist
    expect(find.text('MIAO PHOTO TOOLS'), findsOneWidget);
    expect(find.text('AESTHETIC CAPTURE'), findsOneWidget);

    // 3. Verify specific item exists
    expect(find.text('全屏预览'), findsOneWidget);
    expect(find.text('心跳捕捉'), findsOneWidget);

    // 4. Verify BackdropFilter is used (for Gaussian Blur)
    // Note: In tests, BackdropFilter might be buried in the tree
    final backdropFilterFinder = find.byType(BackdropFilter);
    expect(backdropFilterFinder, findsOneWidget);
  });
}
