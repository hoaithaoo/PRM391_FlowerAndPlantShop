import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_flower_mobile/features/profile/state/current_avatar.dart';

void main() {
  Widget host(ValueNotifier<String?> notifier, {Widget? child}) {
    return MaterialApp(
      home: CurrentAvatar(
        notifier: notifier,
        child: Scaffold(body: Center(child: child ?? const UserAvatar())),
      ),
    );
  }

  CircleAvatar avatar(WidgetTester tester) =>
      tester.widget<CircleAvatar>(find.byType(CircleAvatar));

  testWidgets('chưa có ảnh thì hiện icon người', (tester) async {
    final notifier = ValueNotifier<String?>(null);
    addTearDown(notifier.dispose);
    await tester.pumpWidget(host(notifier));

    expect(avatar(tester).foregroundImage, isNull);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('cập nhật URL thì mọi avatar đổi theo ảnh hồ sơ', (tester) async {
    final notifier = ValueNotifier<String?>(null);
    addTearDown(notifier.dispose);
    late BuildContext innerContext;
    await tester.pumpWidget(
      host(
        notifier,
        child: Builder(
          builder: (context) {
            innerContext = context;
            return const UserAvatar();
          },
        ),
      ),
    );

    CurrentAvatar.update(innerContext, 'https://cdn.test/me.png');
    await tester.pump();

    final image = avatar(tester).foregroundImage;
    expect(image, isA<NetworkImage>());
    expect((image! as NetworkImage).url, 'https://cdn.test/me.png');
  });
}
