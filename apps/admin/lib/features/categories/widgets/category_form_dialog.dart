import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plant_flower_shared/plant_flower_shared.dart';
import 'package:plant_flower_ui/plant_flower_ui.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';

class CategoryFormDialog extends StatefulWidget {
  final CategoryModel? category;

  const CategoryFormDialog({super.key, this.category});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _descController;
  late final TextEditingController _sortOrderController;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _slugController = TextEditingController(text: widget.category?.slug ?? '');
    _descController = TextEditingController(text: widget.category?.description ?? '');
    _sortOrderController = TextEditingController(
      text: widget.category != null ? widget.category!.sortOrder.toString() : '1',
    );

    _nameController.addListener(() {
      if (!isEditing && _nameController.text.isNotEmpty) {
        _slugController.text = _toSlug(_nameController.text);
      }
    });
  }

  String _toSlug(String input) {
    const vietnamese = 'aáàảãạăắằẳẵặâấầẩẫậeéèẻẽẹêếềểễệiíìỉĩịoóòỏõọôốồổỗộơớờởỡợuúùủũụưứừửữựyýỳỷỹỵdđ';
    const english    = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuuuyyyyyd-';
    
    String slug = input.toLowerCase().trim();
    for (int i = 0; i < vietnamese.length; i++) {
      slug = slug.replaceAll(vietnamese[i], i < english.length ? english[i] : '');
    }
    return slug
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final slug = _slugController.text.trim().isNotEmpty
          ? _slugController.text.trim()
          : _toSlug(name);
      final desc = _descController.text.trim();
      final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 1;

      final category = CategoryModel(
        id: widget.category?.id ?? '',
        name: name,
        slug: slug,
        description: desc.isNotEmpty ? desc : null,
        sortOrder: sortOrder,
      );

      if (isEditing) {
        context.read<CategoryBloc>().add(UpdateCategoryEvent(category));
      } else {
        context.read<CategoryBloc>().add(AddCategoryEvent(category));
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Sửa Danh Mục' : 'Thêm Danh Mục Mới',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  
                  // Category Name
                  Text(
                    'Tên danh mục *',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Hoa Cưới & Dạ Tiệc',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập tên danh mục';
                      }
                      if (val.trim().length < 2 || val.trim().length > 100) {
                        return 'Tên danh mục phải từ 2 đến 100 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Slug
                  Text(
                    'Đường dẫn định danh (Slug) *',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _slugController,
                    decoration: InputDecoration(
                      hintText: 'hoa-cuoi-da-tiec',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.link, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập slug danh mục';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Sort Order
                  Text(
                    'Thứ tự hiển thị',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _sortOrderController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '1',
                      prefixIcon: const Icon(Icons.sort, size: 20),
                    ),
                    validator: (val) {
                      if (val != null && val.isNotEmpty) {
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null || parsed < 0) {
                          return 'Thứ tự hiển thị phải là số nguyên không âm';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Mô tả danh mục',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Mô tả chi tiết về nhóm hoa/cây cảnh này...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
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
                          foregroundColor: AppColors.textLight,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(isEditing ? 'Cập nhật' : 'Thêm danh mục'),
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
