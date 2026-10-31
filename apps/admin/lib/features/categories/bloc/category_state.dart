import 'package:equatable/equatable.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;

  const CategoryLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class CategoryActionSuccess extends CategoryState {
  final String message;

  const CategoryActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CategoryError extends CategoryState {
  final String message;

  const CategoryError(this.message);

  @override
  List<Object?> get props => [message];
}
