import 'package:equatable/equatable.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final String? selectedCategory;
  final String? searchQuery;

  const ProductLoaded({
    required this.products,
    this.categories = const [],
    this.selectedCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [products, categories, selectedCategory, searchQuery];

  ProductLoaded copyWith({
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ProductActionSuccess extends ProductState {
  final String message;

  const ProductActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
