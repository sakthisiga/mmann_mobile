import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../farm/state/farm_notifier.dart';
import '../../plot/state/plot_notifier.dart';
import '../data/document_model.dart';
import '../state/document_notifier.dart';

class AddDocumentModal extends ConsumerStatefulWidget {
  final FarmDocumentModel? docToEdit;

  const AddDocumentModal({super.key, this.docToEdit});

  static Future<void> show(BuildContext context, {FarmDocumentModel? docToEdit}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddDocumentModal(docToEdit: docToEdit),
    );
  }

  @override
  ConsumerState<AddDocumentModal> createState() => _AddDocumentModalState();
}

class _AddDocumentModalState extends ConsumerState<AddDocumentModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _docNumberController;
  late final TextEditingController _issuedByController;
  late final TextEditingController _issueDateController;
  late final TextEditingController _expiryDateController;

  String _selectedCategory = 'patta_chitta';
  String _selectedPlotId = '';

  String? _fileName;
  String? _mimeType;
  int? _fileSizeBytes;
  String? _fileDataUrl;
  bool _isProcessingFile = false;
  String? _fileError;

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

  @override
  void initState() {
    super.initState();
    final edit = widget.docToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _docNumberController =
        TextEditingController(text: edit?.documentNumber ?? '');
    _issuedByController = TextEditingController(text: edit?.issuedBy ?? '');
    _issueDateController = TextEditingController(text: edit?.issueDate ?? '');
    _expiryDateController = TextEditingController(text: edit?.expiryDate ?? '');

    if (edit != null) {
      _selectedCategory = edit.category;
      _selectedPlotId = edit.plotId ?? '';
      _fileName = edit.fileName;
      _mimeType = edit.mimeType;
      _fileSizeBytes = edit.fileSizeBytes;
      _fileDataUrl = edit.fileDataUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _docNumberController.dispose();
    _issuedByController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1970),
      lastDate: DateTime(2060),
    );
    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => controller.text = formatted);
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1100,
        maxHeight: 1100,
        imageQuality: 70,
      );
      if (photo != null) {
        await _processXFile(photo, 'image/jpeg');
      }
    } catch (e) {
      setState(() => _fileError = 'Failed to take photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1100,
        maxHeight: 1100,
        imageQuality: 70,
      );
      if (image != null) {
        await _processXFile(image, 'image/jpeg');
      }
    } catch (e) {
      setState(() => _fileError = 'Failed to select image: $e');
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        final bytes = platformFile.bytes ??
            (platformFile.path != null
                ? await File(platformFile.path!).readAsBytes()
                : null);
        if (bytes == null) return;
        if (bytes.lengthInBytes > 600 * 1024) {
          setState(() {
            final loc = AppLocalizations(ref.read(localeProvider));
            _fileError = loc.tr('file_size_limit_exceeded');
          });
          return;
        }
        final base64String = base64Encode(bytes);
        setState(() {
          _fileError = null;
          _fileName = platformFile.name;
          _mimeType = 'application/pdf';
          _fileSizeBytes = bytes.lengthInBytes;
          _fileDataUrl = 'data:application/pdf;base64,$base64String';
        });
      }
    } catch (e) {
      setState(() => _fileError = 'Failed to select PDF: $e');
    }
  }

  Future<void> _processXFile(XFile file, String fallbackMime) async {
    setState(() => _isProcessingFile = true);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 600 * 1024) {
        setState(() {
          _isProcessingFile = false;
          final loc = AppLocalizations(ref.read(localeProvider));
          _fileError = loc.tr('file_size_limit_exceeded');
        });
        return;
      }
      final name = file.name.isNotEmpty ? file.name : 'document.jpg';
      final mime = file.mimeType ?? fallbackMime;
      final base64String = base64Encode(bytes);
      setState(() {
        _fileError = null;
        _fileName = name;
        _mimeType = mime;
        _fileSizeBytes = bytes.lengthInBytes;
        _fileDataUrl = 'data:$mime;base64,$base64String';
        _isProcessingFile = false;
      });
    } catch (e) {
      setState(() {
        _isProcessingFile = false;
        _fileError = 'Error processing file: $e';
      });
    }
  }

  void _showAttachmentOptions(BuildContext context, AppLocalizations loc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.lightPrimary),
                title: Text(loc.tr('take_photo'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF4F46E5)),
                title: Text(loc.tr('choose_from_gallery'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFFE11D48)),
                title: Text(loc.tr('choose_pdf'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final activeFarm = ref.read(farmNotifierProvider).activeFarm;
    if (widget.docToEdit == null && activeFarm == null) return;

    final notifier = ref.read(documentNotifierProvider.notifier);
    bool success;

    if (widget.docToEdit != null) {
      success = await notifier.updateDocument(
        id: widget.docToEdit!.id,
        plotId: _selectedPlotId.isNotEmpty ? _selectedPlotId : null,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        documentNumber: _docNumberController.text.trim(),
        issuedBy: _issuedByController.text.trim(),
        issueDate: _issueDateController.text.trim(),
        expiryDate: _expiryDateController.text.trim(),
        fileName: _fileName,
        mimeType: _mimeType,
        fileSizeBytes: _fileSizeBytes,
        fileDataUrl: _fileDataUrl,
      );
    } else {
      success = await notifier.createDocument(
        farmId: activeFarm!.id,
        plotId: _selectedPlotId.isNotEmpty ? _selectedPlotId : null,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        documentNumber: _docNumberController.text.trim(),
        issuedBy: _issuedByController.text.trim(),
        issueDate: _issueDateController.text.trim(),
        expiryDate: _expiryDateController.text.trim(),
        fileName: _fileName,
        mimeType: _mimeType,
        fileSizeBytes: _fileSizeBytes,
        fileDataUrl: _fileDataUrl,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(ref.watch(localeProvider));
    final docState = ref.watch(documentNotifierProvider);
    final activeFarm = ref.watch(farmNotifierProvider).activeFarm;
    final plots =
        ref.watch(plotNotifierProvider).plotsForFarm(activeFarm?.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.docToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEditing ? loc.tr('edit_document') : loc.tr('add_document'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              // DPDP Act 2023 Guard Notice
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF059669).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.tr('dpdp_no_aadhaar_hint'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: loc.tr('doc_title'),
                  hintText: loc.tr('doc_title_hint'),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: loc.tr('doc_category'),
                ),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          loc.tr('cat_$c'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: plots.any((p) => p.id == _selectedPlotId)
                    ? _selectedPlotId
                    : '',
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: loc.tr('linked_plot'),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(loc.tr('all_plots_farm_wide')),
                  ),
                  ...plots.map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  setState(() => _selectedPlotId = v ?? '');
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _docNumberController,
                      decoration: InputDecoration(
                        labelText: loc.tr('doc_number'),
                        hintText: loc.tr('doc_number_hint'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _issuedByController,
                      decoration: InputDecoration(
                        labelText: loc.tr('issued_by'),
                        hintText: loc.tr('issued_by_hint'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _issueDateController,
                      readOnly: true,
                      onTap: () => _pickDate(_issueDateController),
                      decoration: InputDecoration(
                        labelText: loc.tr('issue_date'),
                        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      readOnly: true,
                      onTap: () => _pickDate(_expiryDateController),
                      decoration: InputDecoration(
                        labelText: loc.tr('expiry_date'),
                        suffixIcon: const Icon(Icons.event_repeat_rounded, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Document File Attachment Section
              Text(
                loc.tr('attach_file'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151D2A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF222D42) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: _isProcessingFile
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Processing document...',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : _fileName != null
                        ? Row(
                            children: [
                              if (_fileDataUrl != null &&
                                  _fileDataUrl!.startsWith('data:image')) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    base64Decode(_fileDataUrl!.split(',').last),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 48,
                                      height: 48,
                                      color: isDark
                                          ? AppColors.darkCardBorder
                                          : Colors.grey[200],
                                      child: const Icon(Icons.image_rounded, size: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ] else ...[
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Color(0xFFE11D48),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fileName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_formatBytes(_fileSizeBytes ?? 0)} · ${_mimeType ?? 'file'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Change',
                                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                                onPressed: () => _showAttachmentOptions(context, loc),
                              ),
                              IconButton(
                                tooltip: loc.tr('remove_file'),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: AppColors.lightAccentCoral,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _fileName = null;
                                    _mimeType = null;
                                    _fileSizeBytes = null;
                                    _fileDataUrl = null;
                                    _fileError = null;
                                  });
                                },
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: () => _showAttachmentOptions(context, loc),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate_rounded,
                                      color: Color(0xFF4F46E5),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          loc.tr('attach_file'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Camera, Gallery or PDF (max 600 KB)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
              if (_fileError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _fileError!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightAccentCoral,
                  ),
                ),
              ],
              if (docState.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  docState.errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightAccentCoral,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: docState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    docState.isLoading
                        ? loc.tr('saving')
                        : (isEditing
                            ? loc.tr('save_changes')
                            : loc.tr('save_document')),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

