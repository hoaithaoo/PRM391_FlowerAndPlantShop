import 'package:flutter/material.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';

import '../features/products/data/product_repository.dart';
import '../features/products/data/product_scope.dart';
import '../features/products/product_routes.dart';
import 'main_shell.dart';

class PlantFlowerApp extends StatelessWidget {
  const PlantFlowerApp({super.key, required this.productRepository});

  final ProductRepository productRepository;

  @override
  Widget build(BuildContext context) {
    return ProductScope(
      repository: productRepository,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nhà Có Hoa',
        theme: AppTheme.data(),
        home: const MainShell(),
        onGenerateRoute: ProductRoutes.onGenerateRoute,
      ),
    );
  }
}
