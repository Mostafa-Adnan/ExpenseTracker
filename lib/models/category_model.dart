import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'color': color.value,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      emoji: map['emoji'],
      color: Color(map['color'] as int),
      isDefault: (map['isDefault'] as int) == 1,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? emoji,
    Color? color,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  static List<CategoryModel> get defaults => [
        // Expense categories
        CategoryModel(
          id: 'food',
          name: 'أكل ومشروبات',
          emoji: '🍔',
          color: AppColors.categoryColors[4],
          isDefault: true,
        ),
        CategoryModel(
          id: 'transport',
          name: 'مواصلات',
          emoji: '🚗',
          color: AppColors.categoryColors[7],
          isDefault: true,
        ),
        CategoryModel(
          id: 'shopping',
          name: 'تسوق',
          emoji: '🛍️',
          color: AppColors.categoryColors[6],
          isDefault: true,
        ),
        CategoryModel(
          id: 'health',
          name: 'صحة وطب',
          emoji: '💊',
          color: AppColors.categoryColors[2],
          isDefault: true,
        ),
        CategoryModel(
          id: 'education',
          name: 'تعليم',
          emoji: '📚',
          color: AppColors.categoryColors[0],
          isDefault: true,
        ),
        CategoryModel(
          id: 'bills',
          name: 'فواتير',
          emoji: '📄',
          color: AppColors.categoryColors[3],
          isDefault: true,
        ),
        CategoryModel(
          id: 'entertainment',
          name: 'ترفيه',
          emoji: '🎮',
          color: AppColors.categoryColors[1],
          isDefault: true,
        ),
        CategoryModel(
          id: 'home',
          name: 'منزل',
          emoji: '🏠',
          color: AppColors.categoryColors[5],
          isDefault: true,
        ),
        // Income categories
        CategoryModel(
          id: 'salary',
          name: 'راتب',
          emoji: '💼',
          color: AppColors.categoryColors[2],
          isDefault: true,
        ),
        CategoryModel(
          id: 'freelance',
          name: 'عمل حر',
          emoji: '💻',
          color: AppColors.categoryColors[0],
          isDefault: true,
        ),
        CategoryModel(
          id: 'gift',
          name: 'هدية',
          emoji: '🎁',
          color: AppColors.categoryColors[6],
          isDefault: true,
        ),
        CategoryModel(
          id: 'investment',
          name: 'استثمار',
          emoji: '📈',
          color: AppColors.categoryColors[1],
          isDefault: true,
        ),
        CategoryModel(
          id: 'other',
          name: 'أخرى',
          emoji: '💡',
          color: AppColors.categoryColors[9],
          isDefault: true,
        ),
      ];
}
