import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/product_form_dialog.dart';
import '../../categories/screens/category_management_screen.dart';
import '../../categories/bloc/category_bloc.dart';
import '../../categories/bloc/category_event.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const FetchProductsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<ProductBloc>().add(
      FetchProductsEvent(search: query.trim(), categoryId: _selectedCategory),
    );
  }

  void _onCategorySelected(String? catId) {
    setState(() {
      _selectedCategory = catId;
    });
    context.read<ProductBloc>().add(
      FetchProductsEvent(
        search: _searchController.text.trim(),
        categoryId: _selectedCategory,
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Xóa sản phẩm?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${product.name}" khỏi danh mục quản lý?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCancelled,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ProductBloc>().add(DeleteProductEvent(product.id));
            },
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Sản Phẩm & Danh Mục',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới danh sách',
              onPressed: () {
                context.read<ProductBloc>().add(
                  FetchProductsEvent(
                    search: _searchController.text.trim(),
                    categoryId: _selectedCategory,
                  ),
                );
                context.read<CategoryBloc>().add(const FetchCategoriesEvent());
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.local_florist, size: 18),
                text: 'Sản phẩm hoa & chậu',
              ),
              Tab(
                icon: Icon(Icons.category, size: 18),
                text: 'Danh mục',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProductTab(),
            const CategoryManagementScreen(showAppBar: false),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTab() {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        icon: const Icon(Icons.add),
        label: Text(
          'Thêm Sản Phẩm',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          final state = context.read<ProductBloc>().state;
          final categories = state is ProductLoaded
              ? state.categories
              : <CategoryModel>[];
          showDialog(
            context: context,
            builder: (_) => BlocProvider.value(
              value: context.read<ProductBloc>(),
              child: ProductFormDialog(categories: categories),
            ),
          );
        },
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusDelivered,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is ProductError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusCancelled,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final categories = state is ProductLoaded
              ? state.categories
              : <CategoryModel>[];

          return Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm hoa, cây cảnh...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Filter Chips
                    if (categories.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('Tất cả'),
                                selected: _selectedCategory == null,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == null
                                      ? Colors.white
                                      : AppColors.textHeading,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) => _onCategorySelected(null),
                              ),
                            ),
                            ...categories.map((c) {
                              final isSelected = _selectedCategory == c.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(c.name),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textHeading,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  onSelected: (_) => _onCategorySelected(c.id),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Product List
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is ProductLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (state is ProductLoaded) {
                      final products = state.products;

                      if (products.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Không tìm thấy sản phẩm nào',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHeading,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<ProductBloc>().add(
                            FetchProductsEvent(
                              search: _searchController.text.trim(),
                              categoryId: _selectedCategory,
                            ),
                          );
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: products.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final p = products[index];
                            return _buildProductCard(p, categories);
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel p, List<CategoryModel> categories) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 76,
                height: 76,
                color: AppColors.surfacePastel,
                child: Image.network(
                  p.imageUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_florist,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.categoryName!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  Text(
                    p.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _currencyFormat.format(p.displayPrice),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                      if (p.salePrice != null && p.salePrice! > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          _currencyFormat.format(p.price),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stock indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: p.isLowStock
                              ? AppColors.statusCancelled.withValues(
                                  alpha: 0.12,
                                )
                              : AppColors.statusDelivered.withValues(
                                  alpha: 0.12,
                                ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.isLowStock
                              ? 'Kho: ${p.stock} (Sắp hết)'
                              : 'Kho: ${p.stock}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: p.isLowStock
                                ? AppColors.statusCancelled
                                : AppColors.statusDelivered,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Edit Button
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Chỉnh sửa',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: context.read<ProductBloc>(),
                              child: ProductFormDialog(
                                product: p,
                                categories: categories,
                              ),
                            ),
                          );
                        },
                      ),
                      // Delete Button
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppColors.statusCancelled,
                        ),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Xóa',
                        onPressed: () => _confirmDelete(p),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
