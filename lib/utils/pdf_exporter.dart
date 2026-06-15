import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class PdfExporter {
  static pw.Font? _arabicFont;

  static Future<pw.Font> _getArabicFont() async {
    if (_arabicFont != null) return _arabicFont!;
    final data = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
    _arabicFont = pw.Font.ttf(data.buffer.asByteData());
    return _arabicFont!;
  }

  // دالة مساعدة لإنشاء نص عربي مع الخط والاتجاه
  static pw.Widget _arabicText(String text,
      {double fontSize = 12,
      pw.FontWeight fontWeight = pw.FontWeight.normal,
      PdfColor? color,          // ✅ التصحيح: استخدام PdfColor بدلاً من pw.Color
      pw.TextAlign? textAlign}) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        font: _arabicFont,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? PdfColors.black,
      ),
      textDirection: pw.TextDirection.rtl,
      textAlign: textAlign ?? pw.TextAlign.right,
    );
  }

  static Future<void> exportTransactions({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required String periodLabel,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numFormat = NumberFormat('#,##0.##');

    _arabicFont = await _getArabicFont();

    CategoryModel? getCat(String id) {
      try {
        return categories.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#7C5CBF'),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _arabicText('تقرير المصاريف', fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              _arabicText(periodLabel, fontSize: 14, color: PdfColors.white),
            ],
          ),
        ),
        build: (ctx) => [
          pw.Row(
            children: [
              _summaryCard('الدخل', numFormat.format(totalIncome), PdfColor.fromHex('#4CAF50')),
              pw.SizedBox(width: 12),
              _summaryCard('المصاريف', numFormat.format(totalExpense), PdfColor.fromHex('#EF5350')),
              pw.SizedBox(width: 12),
              _summaryCard(
                'الرصيد',
                numFormat.format(balance),
                balance >= 0 ? PdfColor.fromHex('#7C5CBF') : PdfColor.fromHex('#EF5350'),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          _arabicText('قائمة العمليات (${transactions.length})', fontSize: 16, fontWeight: pw.FontWeight.bold),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('#E8E0F0'), width: 0.5),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EDE7F6')),
                children: ['الوصف', 'الفئة', 'التاريخ', 'المبلغ', 'النوع'].map((h) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: _arabicText(h, fontSize: 11, fontWeight: pw.FontWeight.bold),
                  );
                }).toList(),
              ),
              ...transactions.map((tx) {
                final cat = getCat(tx.categoryId);
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: transactions.indexOf(tx).isEven ? PdfColors.white : PdfColor.fromHex('#F8F5FF'),
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: _arabicText(tx.title, fontSize: 10),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: _arabicText(cat?.name ?? '-', fontSize: 10),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: pw.Text(dateFormat.format(tx.date), style: pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: pw.Text(
                        numFormat.format(tx.amount),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: tx.isIncome ? PdfColor.fromHex('#2E7D32') : PdfColor.fromHex('#C62828'),
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: _arabicText(tx.isIncome ? 'دخل' : 'مصروف',
                          fontSize: 10,
                          color: tx.isIncome ? PdfColor.fromHex('#2E7D32') : PdfColor.fromHex('#C62828')),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),
          _arabicText('تم إنشاء هذا التقرير بواسطة تطبيق تتبع المصاريف', fontSize: 10, color: PdfColors.grey),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  static pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _arabicText(label, fontSize: 12, color: PdfColors.white),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    font: _arabicFont)),
          ],
        ),
      ),
    );
  }
}