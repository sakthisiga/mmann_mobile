import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../farm/state/farm_notifier.dart';
import '../../plot/state/plot_notifier.dart';
import '../data/document_model.dart';
import '../state/document_notifier.dart';
import 'add_document_modal.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _selectedCategory = 'all';

  static const _categories = [
    'patta_chitta',
    'adangal_rtc',
    'fmb_sketch',
    'lease_agreement',
    'kcc_passbook',
    'eb_service_card',
    'soil_health_card',
    'input_receipt',
    'crop_insurance',
    'other',
  ];

  static const List<Color> _cardPalette = [
    Color(0xFF059669), // Emerald
    Color(0xFF4F46E5), // Indigo
    Color(0xFFD97706), // Amber
    Color(0xFF0284C7), // Sky
    Color(0xFFE11D48), // Rose
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(ref.watch(localeProvider));
    final farmState = ref.watch(farmNotifierProvider);
    final docState = ref.watch(documentNotifierProvider);
    final plotState = ref.watch(plotNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeFarm = farmState.activeFarm;
    final allDocs = docState.documentsForFarm(activeFarm?.id);
    final filteredDocs = _selectedCategory == 'all'
        ? allDocs
        : allDocs.where((d) => d.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.tr('docs_page_title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (activeFarm != null)
              Text(
                activeFarm.name,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
          ],
        ),
        actions: [
          if (activeFarm != null)
            IconButton(
              onPressed: () => AddDocumentModal.show(context),
              icon: const Icon(Icons.note_add_rounded),
              tooltip: loc.tr('add_document'),
            ),
        ],
      ),
      floatingActionButton: activeFarm != null
          ? FloatingActionButton.extended(
              onPressed: () => AddDocumentModal.show(context),
              backgroundColor:
                  isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                loc.tr('add_document'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(documentNotifierProvider.notifier).loadDocuments(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            // Multi-Color KPI Summary Row
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    label: loc.tr('total_documents'),
                    value: '${allDocs.length}',
                    color: const Color(0xFF4F46E5),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryTile(
                    label: loc.tr('land_revenue_docs'),
                    value: '${docState.landDocsCountForFarm(activeFarm?.id)}',
                    color: const Color(0xFF059669),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryTile(
                    label: loc.tr('expiring_soon_alert'),
                    value: '${docState.expiringCountForFarm(activeFarm?.id)}',
                    color: const Color(0xFFD97706),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(loc.tr('all_categories')),
                    selected: _selectedCategory == 'all',
                    onSelected: (_) =>
                        setState(() => _selectedCategory = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(loc.tr('cat_$cat')),
                        selected: _selectedCategory == cat,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Documents List
            if (filteredDocs.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_copy_rounded,
                      size: 44,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.tr('no_documents_yet'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.tr('add_document_hint'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredDocs.asMap().entries.map(
                    (entry) => _buildDocCard(
                      context,
                      entry.value,
                      entry.key,
                      loc,
                      isDark,
                      plotState,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [color.withValues(alpha: 0.2), AppColors.darkSurface]
              : [color.withValues(alpha: 0.12), AppColors.white],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.45 : 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, width: double.infinity, color: color),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(
    BuildContext context,
    FarmDocumentModel doc,
    int index,
    AppLocalizations loc,
    bool isDark,
    dynamic plotState,
  ) {
    final accent = _cardPalette[index % _cardPalette.length];
    final linkedPlot = doc.plotId != null
        ? plotState.plotsList
            .where((p) => p.id == doc.plotId)
            .map((p) => p.name as String)
            .firstOrNull
        : null;

    Color statusColor;
    String statusText;
    if (doc.renewalStatus == 'EXPIRED') {
      statusColor = const Color(0xFFE11D48);
      statusText = loc.tr('renewal_expired');
    } else if (doc.renewalStatus == 'EXPIRING_SOON') {
      statusColor = const Color(0xFFD97706);
      statusText =
          '${loc.tr('renewal_expiring_soon')} (${doc.daysUntilExpiry ?? 0}d)';
    } else if (doc.renewalStatus == 'VALID') {
      statusColor = const Color(0xFF059669);
      statusText = loc.tr('renewal_valid');
    } else {
      statusColor = const Color(0xFF64748B);
      statusText = loc.tr('renewal_no_expiry');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [accent.withValues(alpha: 0.16), AppColors.darkSurface]
              : [accent.withValues(alpha: 0.09), AppColors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.55)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent, accent.withValues(alpha: 0.75)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loc.tr('cat_${doc.category}'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          AddDocumentModal.show(context, docToEdit: doc),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDeleteDoc(context, doc, loc),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.lightAccentCoral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (doc.documentNumber != null &&
                        doc.documentNumber!.isNotEmpty)
                      _buildTag('# ${doc.documentNumber}', isDark),
                    if (linkedPlot != null) _buildTag(linkedPlot, isDark),
                    if (doc.expiryDate != null && doc.expiryDate!.isNotEmpty)
                      _buildTag('Exp: ${doc.expiryDate}', isDark),
                    if (doc.fileName != null && doc.fileName!.isNotEmpty)
                      _buildTag(
                        '${doc.fileName} (${_formatBytes(doc.fileSizeBytes ?? 0)})',
                        isDark,
                        icon: Icons.attachment_rounded,
                      ),
                  ],
                ),
                if (doc.fileDataUrl != null && doc.fileDataUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showDocumentViewer(context, doc, loc),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            doc.mimeType?.startsWith('image/') == true ||
                                    doc.fileDataUrl!.startsWith('data:image')
                                ? Icons.image_outlined
                                : Icons.picture_as_pdf_outlined,
                            size: 16,
                            color: accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.tr('view_attachment'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, bool isDark, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground
            : AppColors.lightPillBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentViewer(
    BuildContext context,
    FarmDocumentModel doc,
    AppLocalizations loc,
  ) {
    if (doc.fileDataUrl == null || doc.fileDataUrl!.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isImage = doc.mimeType?.startsWith('image/') == true ||
        doc.fileDataUrl!.startsWith('data:image');

    if (isImage) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 650, maxWidth: 500),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151D2A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (doc.fileName != null)
                              Text(
                                doc.fileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: Container(
                    color: Colors.black87,
                    alignment: Alignment.center,
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Image.memory(
                        base64Decode(doc.fileDataUrl!.split(',').last),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Icon(Icons.broken_image_rounded,
                              size: 48, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.tr('cat_${doc.category}'),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      if (doc.fileSizeBytes != null)
                        Text(
                          _formatBytes(doc.fileSizeBytes!),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // PDF or other document
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  color: Color(0xFFE11D48)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doc.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (doc.fileName != null) ...[
                Text('File: ${doc.fileName!}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
              ],
              if (doc.fileSizeBytes != null) ...[
                Text('Size: ${_formatBytes(doc.fileSizeBytes!)}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
              ],
              if (doc.documentNumber != null &&
                  doc.documentNumber!.isNotEmpty) ...[
                Text('Doc #: ${doc.documentNumber!}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
              ],
              if (doc.issuedBy != null && doc.issuedBy!.isNotEmpty) ...[
                Text('Issued by: ${doc.issuedBy!}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
              ],
              Text('Category: ${loc.tr('cat_${doc.category}')}',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.tr('cancel')),
            ),
          ],
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _confirmDeleteDoc(
    BuildContext context,
    FarmDocumentModel doc,
    AppLocalizations loc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          loc.tr('confirm_delete_doc_title'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Text('${doc.title}\n\n${loc.tr('confirm_delete_doc_desc')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightAccentCoral,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.tr('delete_document')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(documentNotifierProvider.notifier).deleteDocument(doc.id);
    }
  }
}
