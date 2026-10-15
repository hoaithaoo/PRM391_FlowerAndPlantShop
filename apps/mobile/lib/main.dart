import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/auth.dart';

// Truyền qua --dart-define, không hardcode key trong source (team-conventions §7)
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AuthRepository authRepository;
  if (_supabaseUrl.isNotEmpty && _supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );
    authRepository = SupabaseAuthRepository(Supabase.instance.client.auth);
  } else {
    // Chưa cấu hình Supabase: chạy demo với dữ liệu giả (OTP đúng là 123456)
    debugPrint('SUPABASE_URL chưa được cấu hình, dùng MockAuthRepository.');
    authRepository = MockAuthRepository();
  }

  runApp(PlantFlowerApp(authRepository: authRepository));
}

class PlantFlowerApp extends StatelessWidget {
  const PlantFlowerApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      repository: authRepository,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flower & Plant Shop',
        theme: AuthTheme.data(ThemeData(useMaterial3: true)),
        initialRoute: AuthRoutes.gate,
        onGenerateRoute: AuthRoutes.onGenerateRoute,
      ),
    );
  }
}
