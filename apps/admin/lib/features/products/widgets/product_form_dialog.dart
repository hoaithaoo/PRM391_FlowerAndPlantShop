import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';

class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final List<CategoryModel> categories;

  const ProductFormDialog({
    super.key,
    this.product,
    this.categories = const [],
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descController;
  String? _selectedCategoryId;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product != null
          ? widget.product!.price.toInt().toString()
          : '',
    );
    _salePriceController = TextEditingController(
      text: widget.product?.salePrice != null
          ? widget.product!.salePrice!.toInt().toString()
          : '',
    );
    _stockController = TextEditingController(
      text: widget.product != null ? widget.product!.stock.toString() : '10',
    );
    _descController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _selectedCategoryId =
        widget.product?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final salePrice = _salePriceController.text.trim().isNotEmpty
          ? double.tryParse(_salePriceController.text.trim())
          : null;
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;
      final desc = _descController.text.trim();

      CategoryModel? cat;
      try {
        cat = widget.categories.firstWhere((c) => c.id == _selectedCategoryId);
      } catch (_) {}

      final product = ProductModel(
        id: widget.product?.id ?? '',
        name: name,
        slug: name.toLowerCase().replaceAll(' ', '-'),
        description: desc,
        price: price,
        salePrice: salePrice,
        stock: stock,
        categoryId: _selectedCategoryId,
        categoryName: cat?.name,
        imageUrl:
            widget.product?.imageUrl ??
            'https://images.unsplash.com/photo-1508615039623-a25605d2b022?w=500',
      );

      if (isEditing) {
        context.read<ProductBloc>().add(UpdateProductEvent(product));
      } else {
        context.read<ProductBloc>().add(AddProductEvent(product));
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit : Icons.add_circle_outline,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing
                              ? 'Sửa thông tin sản phẩm'
                              : 'Thêm sản phẩm mới',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Tên sản phẩm
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên hoa / cây cảnh *',
                      hintText: 'VD: Sen Hồng Tháp Mười',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên sản phẩm';
                      if (v.trim().length < 2 || v.trim().length > 150) {
                        return 'Tên sản phẩm phải từ 2 đến 150 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Danh mục dropdown
                  if (widget.categories.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục sản phẩm',
                      ),
                      items: widget.categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.name,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                    ),
                  const SizedBox(height: 14),

                  // Giá niêm yết & Giá bán ưu đãi
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giá niêm yết (₫) *',
                            hintText: '450000',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Nhập giá tiền';
                            final parsed = double.tryParse(v.trim());
                            if (parsed == null) return 'Phải là số';
                            if (parsed < 1000) return 'Tối thiểu 1.000₫';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _salePriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giá KM (₫)',
                            hintText: '390000',
                          ),
                          validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                              final parsed = double.tryParse(v.trim());
                              if (parsed == null) return 'Phải là số';
                              if (parsed < 1000) return 'Tối thiểu 1.000₫';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tồn kho
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng tồn kho *',
                      hintText: 'VD: 15',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Nhập tồn kho';
                      final parsed = int.tryParse(v.trim());
                      if (parsed == null) return 'Phải là số nguyên';
                      if (parsed < 0) return 'Tồn kho không âm';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Mô tả
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả & Ý nghĩa sản phẩm',
                      hintText: 'Nguồn gốc loài hoa, đặc tính chăm sóc...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Hủy bỏ'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
