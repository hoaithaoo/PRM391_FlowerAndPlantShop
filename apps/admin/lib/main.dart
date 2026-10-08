import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/admin_api_client.dart';
import 'core/observer/app_bloc_observer.dart';
import 'core/theme/admin_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/categories/bloc/category_bloc.dart';
import 'features/categories/bloc/category_event.dart';
import 'features/dashboard/cubit/dashboard_cubit.dart';
import 'features/home/screens/admin_main_screen.dart';
import 'features/orders/bloc/order_bloc.dart';
import 'features/products/bloc/product_bloc.dart';
import 'features/users/bloc/user_bloc.dart';
import 'features/finance/bloc/finance_bloc.dart';
import 'features/finance/bloc/finance_event.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  runApp(const PlantFlowerAdminApp());
}

class PlantFlowerAdminApp extends StatelessWidget {
  const PlantFlowerAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AdminApiClient>(
      create: (context) => AdminApiClient(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              apiClient: context.read<AdminApiClient>(),
            )..add(CheckAuthSessionEvent()),
          ),
          BlocProvider<DashboardCubit>(
            create: (context) => DashboardCubit(
              apiClient: context.read<AdminApiClient>(),
            ),
          ),
          BlocProvider<CategoryBloc>(
            create: (context) => CategoryBloc(
              apiClient: context.read<AdminApiClient>(),
            )..add(const FetchCategoriesEvent()),
          ),
          BlocProvider<ProductBloc>(
            create: (context) => ProductBloc(
              apiClient: context.read<AdminApiClient>(),
            ),
          ),
          BlocProvider<OrderBloc>(
            create: (context) => OrderBloc(
              apiClient: context.read<AdminApiClient>(),
            ),
          ),
          BlocProvider<UserBloc>(
            create: (context) => UserBloc(
              apiClient: context.read<AdminApiClient>(),
            ),
          ),
          BlocProvider<FinanceBloc>(
            create: (context) => FinanceBloc(
              apiClient: context.read<AdminApiClient>(),
            )..add(const FetchAllFinanceDataEvent()),
          ),
        ],
        child: MaterialApp(
          title: 'Nhà Có Hoa • Admin Portal',
          debugShowCheckedModeBanner: false,
          theme: AdminTheme.lightTheme,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return AdminMainScreen(profile: state.profile);
              }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
