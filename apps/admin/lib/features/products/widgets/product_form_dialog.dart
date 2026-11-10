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
  late final TextEditingController _imageUrlController;
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
    _imageUrlController = TextEditingController(
      text: widget.product?.imageUrl ?? '',
    );
    _imageUrlController.addListener(_onImageUrlChanged);
    _selectedCategoryId =
        widget.product?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
  }

  void _onImageUrlChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _imageUrlController.removeListener(_onImageUrlChanged);
    _imageUrlController.dispose();
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
      final imageUrl = _imageUrlController.text.trim();

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
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      );

      if (isEditing) {
        context.read<ProductBloc>().add(UpdateProductEvent(product));
      } else {
        context.read<ProductBloc>().add(AddProductEvent(product));
      }
      Navigator.of(context).pop();
    }
  }

  Widget _buildImagePreview() {
    final url = _imageUrlController.text.trim();
    final isValidUrl = url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: isValidUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color: Colors.amber.shade700,
                        size: 36,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Không thể tải ảnh từ liên kết này',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  );
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.grey.shade400,
                    size: 38,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chưa có ảnh sản phẩm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dán đường dẫn ảnh bên dưới để xem trước',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
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

                  // Khung xem trước hình ảnh
                  _buildImagePreview(),
                  const SizedBox(height: 14),

                  // Đường dẫn hình ảnh
                  TextFormField(
                    controller: _imageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'Đường dẫn hình ảnh (URL) *',
                      hintText: 'https://images.unsplash.com/...',
                      prefixIcon: const Icon(Icons.link),
                      suffixIcon: _imageUrlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _imageUrlController.clear();
                              },
                            )
                          : null,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập đường dẫn hình ảnh';
                      }
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null ||
                          !uri.hasScheme ||
                          (!v.trim().startsWith('http://') &&
                              !v.trim().startsWith('https://'))) {
                        return 'Đường dẫn phải bắt đầu bằng http:// hoặc https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

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
                      final validNameRegex = RegExp(r'^[\p{L}\p{N}\s\-_(),.]+$', unicode: true);
                      if (!validNameRegex.hasMatch(v.trim())) {
                        return 'Tên sản phẩm không được chứa ký tự đặc biệt';
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
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Hủy bỏ'),
                      ),
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
