import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactile/tactile.dart';

void main() {
  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );

  testWidgets('TactileButton fires onTap and builds on a Tactile', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(TactileButton(onTap: () => taps++, child: const Text('go'))),
    );

    expect(find.byType(Tactile), findsOneWidget);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('disabled TactileButton does not fire onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        TactileButton(
          onTap: () => taps++,
          enabled: false,
          child: const Text('go'),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(taps, 0);
  });

  testWidgets('TactileTile lays out leading, title, and trailing', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 320,
          child: TactileTile(
            leading: Icon(IconData(0x1, fontFamily: 'x')),
            title: Text('Title'),
            subtitle: Text('Subtitle'),
            trailing: Icon(IconData(0x2, fontFamily: 'x')),
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Subtitle'), findsOneWidget);
    expect(find.byType(Tactile), findsOneWidget);
  });

  testWidgets('shadow flattens as the surface is pressed', (tester) async {
    await tester.pumpWidget(
      host(const TactileCard(child: SizedBox(width: 160, height: 100))),
    );

    BoxShadow firstShadow() {
      final decoration = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(TactileCard),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration as BoxDecoration)
          .firstWhere((d) => d.boxShadow?.isNotEmpty ?? false);
      return decoration.boxShadow!.first;
    }

    final atRest = firstShadow().blurRadius;
    expect(atRest, greaterThan(0));

    await tester.startGesture(tester.getCenter(find.byType(TactileCard)));
    await tester.pump(); // establish ticker
    await tester.pump(const Duration(milliseconds: 120)); // press in

    expect(firstShadow().blurRadius, lessThan(atRest));
  });

  testWidgets('a styled component inherits its style from TactileTheme', (
    tester,
  ) async {
    const themed = Color(0xFF112233);
    await tester.pumpWidget(
      host(
        const TactileTheme(
          data: TactileThemeData(style: TactileStyle(color: themed)),
          child: TactileButton(child: Text('go')),
        ),
      ),
    );

    final surface = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(TactileButton),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration as BoxDecoration)
        .firstWhere((d) => d.color != null);

    // At rest the surface color is the themed color (no press darkening yet).
    expect(surface.color, themed);
  });
}
