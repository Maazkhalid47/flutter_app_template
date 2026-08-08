import 'package:flutter/material.dart';
import 'package:flutter_app_template/theme/app_theme.dart';
import 'package:flutter_app_template/widgets/app_button.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests belong to reusable widgets, not to screens.
///
/// A screen's behaviour lives in its view model (tested without Flutter), so
/// what is left to verify here is exactly what a widget owns: rendering and
/// interaction.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  testWidgets('renders its label and fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(AppButton(label: 'Save', onPressed: () => taps++)),
    );

    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('shows a spinner and swallows taps while loading', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(AppButton(label: 'Save', isLoading: true, onPressed: () => taps++)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    // The double-submit guard: a second tap during an in-flight request must
    // not fire the handler again.
    expect(taps, 0);
  });

  testWidgets('is inert when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(AppButton(label: 'Save', isEnabled: false, onPressed: () => taps++)),
    );

    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    await tester.pump();

    expect(taps, 0);
  });

  testWidgets('renders an icon when one is given', (tester) async {
    await tester.pumpWidget(
      wrap(AppButton(label: 'Refresh', icon: Icons.refresh, onPressed: () {})),
    );

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });

  testWidgets('the text variant does not stretch to full width', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Row(
          children: [AppButton.text(label: 'Later', onPressed: () {})],
        ),
      ),
    );

    final size = tester.getSize(find.byType(AppButton));
    expect(size.width, lessThan(400));
  });
}
