import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الفئات')),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final cats = provider.categories;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader(title: 'الفئات المتاحة (${cats.length})'),
              const SizedBox(height: 12),
              ...cats.map((cat) => _CategoryTile(
                category: cat,
                onDelete: cat.isDefault
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('حذف الفئة', textAlign: TextAlign.right),
                            content: Text('حذف فئة "${cat.name}"؟', textAlign: TextAlign.right),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('حذف'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await context.read<ExpenseProvider>().deleteCategory(cat.id);
                        }
                      },
              )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: Directionality(
        textDirection: TextDirection.rtl,
        child: FloatingActionButton.extended(
          heroTag: 'add_category_fab',
          onPressed: () => _showAddCategorySheet(context),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            'فئة جديدة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          extendedPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          extendedIconLabelSpacing: 6,
          elevation: 4,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddCategorySheet(),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onDelete;

  const _CategoryTile({required this.category, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(category.emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                if (category.isDefault)
                  const Text('فئة افتراضية',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          ),
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
  );
}

// ─── ADD CATEGORY BOTTOM SHEET (Fixed Overflow) ──────────────────────────────

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  String _selectedEmoji = '💡';
  Color _selectedColor = AppColors.categoryColors[0];
  bool _loading = false;

  final _emojis = ['🍔','🚗','🛍️','💊','📚','📄','🎮','🏠','💼','💻','🎁','📈','💡',
    '✈️','🎓','⚽','🎵','📱','🏋️','🌿','🍕','☕','🎪','🏥','🔧','💅','🎨','🐕'];

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await context.read<ExpenseProvider>().addCategory(
      name: _nameCtrl.text.trim(),
      emoji: _selectedEmoji,
      color: _selectedColor,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('فئة جديدة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 20),

              // Preview
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _selectedColor, width: 2),
                ),
                child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 30))),
              ),
              const SizedBox(height: 16),

              // Name field
              TextField(
                controller: _nameCtrl,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'اسم الفئة', hintText: 'مثال: كافيه'),
              ),
              const SizedBox(height: 16),

              // Emoji picker
              const Align(alignment: Alignment.centerRight,
                  child: Text('اختر أيقونة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary))),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _emojis.length,
                  itemBuilder: (_, i) {
                    final e = _emojis[i];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmoji = e),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedEmoji == e ? _selectedColor.withOpacity(0.15) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _selectedEmoji == e ? _selectedColor : Colors.transparent, width: 2),
                        ),
                        child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Color picker
              const Align(alignment: Alignment.centerRight,
                  child: Text('اختر لون', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: AppColors.categoryColors.map((c) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: _selectedColor == c ? 34 : 28,
                    height: _selectedColor == c ? 34 : 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: _selectedColor == c ? AppColors.textPrimary : Colors.transparent, width: 2),
                      boxShadow: _selectedColor == c ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 6)] : [],
                    ),
                    child: _selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      : const Text('إضافة الفئة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}