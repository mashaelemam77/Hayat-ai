import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show LengthLimitingTextInputFormatter, TextInputFormatter;
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../services/app_language.dart';
import '../../services/gemini_analysis_service.dart';
import '../../services/report_service.dart';
import '../../services/stored_audio_opener.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _reportService = ReportService();
  final _geminiAnalysisService = GeminiAnalysisService();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  bool _isSubmitting = false;
  bool _isAnalyzing = false;
  bool _isRecording = false;
  String _imagePath = '';
  String _imageMimeType = '';
  String _audioPath = '';
  String _audioMimeType = 'audio/mp4';
  String _documentPath = '';
  String _lastAnalyzedDescription = '';
  String _lastAnalyzedAttachmentsKey = '';
  String? _analysisMessage;
  String? _nameInputMessage;
  String? _phoneInputMessage;
  GeminiAnalysisResult? _userAnalysis;
  GeminiInlineFile? _analysisImageFile;
  GeminiInlineFile? _analysisAudioFile;
  Uint8List? _imagePreviewBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSubmitReport() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final description = _descController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty || phone.isEmpty || description.isEmpty || location.isEmpty) {
      _showMessage(
        AppLanguage.text(
          'Please enter name, mobile number, report description, and location',
          'يرجى إدخال الاسم ورقم الجوال ووصف البلاغ والموقع',
        ),
        isError: true,
      );
      return;
    }

    if (!_isValidReporterName(name)) {
      _showMessage(
        AppLanguage.text(
          'Name must contain letters only and be at least 2 letters',
          'الاسم يجب أن يكون حروف فقط ولا يقل عن حرفين',
        ),
        isError: true,
      );
      return;
    }

    if (!_isValidMobileNumber(phone)) {
      _showMessage(
        AppLanguage.text(
          'Mobile number must contain exactly 10 digits',
          'رقم الجوال يجب أن يكون 10 أرقام فقط',
        ),
        isError: true,
      );
      return;
    }

    if (_needsFreshAnalysis(description)) {
      await _runUserAnalysis(force: true);
      if (!mounted) return;
    }

    final analysis = _userAnalysis;
    if (analysis == null) {
      _showMessage(
        AppLanguage.text(
          'Analysis is not ready yet. Please try again.',
          'التحليل غير جاهز بعد، حاولي مرة أخرى.',
        ),
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.fact_check_outlined,
                      color: Color(0xFF2D3A8C),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLanguage.text('Report Summary', 'ملخص البلاغ'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryRow(AppLanguage.text('Name', 'الاسم'), name),
                        _summaryRow(
                          AppLanguage.text('Mobile', 'رقم الجوال'),
                          phone,
                        ),
                        _summaryRow(
                          AppLanguage.text('Report subject', 'موضوع البلاغ'),
                          analysis.subject,
                        ),
                        _summaryRow(
                          AppLanguage.text('Report type', 'نوع البلاغ'),
                          analysis.incidentType,
                        ),
                        _summaryRow(
                          AppLanguage.text('Priority', 'الخطورة'),
                          analysis.priority,
                        ),
                        if (location.isNotEmpty)
                          _summaryRow(
                            AppLanguage.text('Location', 'الموقع'),
                            location,
                          ),
                        _summaryRow(
                          AppLanguage.text('Attachments', 'المرفقات'),
                          _attachmentsSummary(),
                        ),
                        _summaryRow(
                          AppLanguage.text('Smart description', 'الوصف الذكي'),
                          analysis.smartDescription,
                        ),
                        if (_imagePreviewBytes != null) ...[
                          const SizedBox(height: 6),
                          _imagePreviewCard(compact: true),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          AppLanguage.text(
                            'Are you sure the entered data is correct?',
                            'هل أنت متأكد من صحة البيانات المدخلة؟',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2D3A8C),
                          side: const BorderSide(color: Color(0xFF2D3A8C)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppLanguage.text('Edit', 'تعديل')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3A8C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(
                          AppLanguage.text(
                            'Confirm and Submit',
                            'تم، إرسال البلاغ',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _submitReport(
        analysis: analysis,
        imageFile: _analysisImageFile,
        audioFile: _analysisAudioFile,
      );
    }
  }

  bool _isValidReporterName(String name) {
    final normalized = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final lettersOnly = normalized.replaceAll(' ', '');
    return lettersOnly.length >= 2 &&
        RegExp(r'^[A-Za-z\u0600-\u06FF ]+$').hasMatch(normalized);
  }

  bool _isValidMobileNumber(String phone) {
    return RegExp(r'^\d{10}$').hasMatch(phone.trim());
  }

  Future<void> _submitReport({
    required GeminiAnalysisResult analysis,
    GeminiInlineFile? imageFile,
    GeminiInlineFile? audioFile,
  }) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();

    setState(() => _isSubmitting = true);

    final imageFileForSave = imageFile ??
        await _inlineFileFromPath(
          _imagePath,
          mimeType: _imageMimeType,
          fallbackMimeType: 'image/jpeg',
          bytes: _imagePreviewBytes,
        );

    try {
      await _reportService.createReport(
        reporterName: name,
        reporterPhone: phone,
        subject: analysis.subject,
        description: analysis.smartDescription,
        location: location,
        type: analysis.incidentType,
        severity: analysis.priority,
        imageAnalysis: analysis.imageAnalysis,
        audioAnalysis: analysis.audioAnalysis,
        aiAnalysis: analysis.aiAnalysis,
        imagePath: _displayableImagePath(imageFileForSave),
        audioPath: _displayableAudioPath(audioFile),
        documentPath: _documentPath,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(
            AppLanguage.text(
              'Report submitted successfully',
              'تم إرسال البلاغ بنجاح',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3A8C),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLanguage.text('OK', 'حسناً')),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      _showMessage('تعذر إرسال البلاغ: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _runUserAnalysis({bool force = false}) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final description = _descController.text.trim();
    final location = _locationController.text.trim();

    if (description.isEmpty) {
      _showMessage(
        AppLanguage.text(
          'Please enter the report description first',
          'اكتبي وصف البلاغ أولاً',
        ),
        isError: true,
      );
      return;
    }

    if (location.isEmpty) {
      _showMessage(
        AppLanguage.text(
          'Please enter or select the report location first',
          'يرجى إدخال أو تحديد موقع البلاغ أولاً',
        ),
        isError: true,
      );
      return;
    }

    if (!force && !_needsFreshAnalysis(description)) return;

    setState(() {
      _isAnalyzing = true;
      _analysisMessage = null;
      _userAnalysis = null;
    });

    GeminiInlineFile? imageFile;
    GeminiInlineFile? audioFile;
    GeminiAnalysisResult analysis;
    String? message;

    try {
      imageFile = await _inlineFileFromPath(
        _imagePath,
        mimeType: _imageMimeType,
        fallbackMimeType: 'image/jpeg',
        bytes: _imagePreviewBytes,
      );
      audioFile = await _inlineFileFromPath(
        _audioPath,
        mimeType: _audioMimeType,
        fallbackMimeType: 'audio/mp4',
      );
      analysis = await _geminiAnalysisService
          .analyzeReport(
            description: description,
            reporterName: name,
            reporterPhone: phone,
            location: location,
            languageCode: AppLanguage.code.value,
            imageFile: imageFile,
            audioFile: audioFile,
          )
          .timeout(const Duration(seconds: 30));
      final audioText = analysis.audioAnalysis.trim();
      final hasUsefulAudioText = audioText.isNotEmpty &&
          !audioText.contains('تم تحليل الصوت ضمن الوصف الذكي') &&
          !audioText.contains('The audio was analyzed as part of the smart description') &&
          !audioText.contains('تم إرفاق تسجيل صوتي') &&
          !audioText.contains('A voice recording was attached');

      if (hasUsefulAudioText && !_descController.text.contains(audioText)) {
        final current = _descController.text.trim();
        _descController.text = current.isEmpty
            ? audioText
            : '$current\n\n${AppLanguage.text('Voice transcription:', 'تفريغ الصوت:')} $audioText';
      }
    } catch (_) {
      analysis = _fallbackAnalysis(description);
      message = AppLanguage.text(
        'Gemini did not finish quickly, so a quick review was prepared from the entered data and attachments.',
        'لم يكتمل Gemini بسرعة، فتم تجهيز مراجعة سريعة من البيانات والمرفقات.',
      );
    }

    if (!mounted) return;
    setState(() {
      _userAnalysis = analysis;
      _analysisImageFile = imageFile;
      _analysisAudioFile = audioFile;
      _analysisMessage = message;
      _lastAnalyzedDescription = _descController.text.trim();
      _lastAnalyzedAttachmentsKey = _attachmentsKey;
      _isAnalyzing = false;
    });
  }

  bool _needsFreshAnalysis(String description) {
    return _userAnalysis == null ||
        _lastAnalyzedDescription != description ||
        _lastAnalyzedAttachmentsKey != _attachmentsKey;
  }

  String get _attachmentsKey => '$_imagePath|$_audioPath|$_documentPath';

  void _clearAnalysis() {
    _userAnalysis = null;
    _analysisImageFile = null;
    _analysisAudioFile = null;
    _analysisMessage = null;
    _lastAnalyzedDescription = '';
    _lastAnalyzedAttachmentsKey = '';
  }

  void _scheduleAnalysisIfReady() {
    if (_descController.text.trim().isEmpty || _isAnalyzing) return;
    unawaited(_runUserAnalysis(force: true));
  }

  GeminiAnalysisResult _fallbackAnalysis(String description) {
    final isArabic = AppLanguage.code.value == 'ar';
    final clean = description.trim().replaceAll(RegExp(r'\s+'), ' ');
    final subject = clean.isEmpty
        ? AppLanguage.text('New report', 'بلاغ جديد')
        : clean.length <= 42
        ? clean
        : '${clean.substring(0, 42)}...';

    return GeminiAnalysisResult(
      subject: subject,
      incidentType: isArabic ? 'أخرى' : 'Other',
      smartDescription: description,
      aiAnalysis: isArabic
          ? 'تم إرسال البلاغ بنجاح. سيتم الاعتماد على وصف المستخدم والمرفقات للمراجعة.'
          : 'The report was submitted successfully. The user description and attachments will be used for review.',
      imageAnalysis: _imagePath.isNotEmpty
          ? isArabic
                ? 'تم إرفاق صورة مع البلاغ وستظهر للضابط.'
                : 'A photo was attached to the report and will be visible to the officer.'
          : '',
      audioAnalysis: _audioPath.isNotEmpty
          ? isArabic
                ? 'تم إرفاق تسجيل صوتي مع البلاغ وسيظهر للضابط.'
                : 'A voice recording was attached to the report and will be visible to the officer.'
          : '',
      priority: isArabic ? 'متوسطة' : 'Medium',
    );
  }

    Future<void> _captureImage() async {
    XFile? image;

    try {
      image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 55,
        maxWidth: 1024,
        maxHeight: 1024,
      );
    } catch (_) {
      image = null;
    }

    image ??= await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _imagePath = image!.path;
      _documentPath = '';
      _imagePreviewBytes = bytes;
      _imageMimeType =
          image.mimeType ?? _mimeTypeFromPath(image.path, 'image/jpeg');
      _clearAnalysis();
    });

    _scheduleAnalysisIfReady();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        if (path != null) _audioPath = path;
        _audioMimeType = kIsWeb
            ? 'audio/webm'
            : _mimeTypeFromPath(path ?? '', 'audio/mp4');
        _clearAnalysis();
      });

      if (_audioPath.isNotEmpty) {
        await _runUserAnalysis(force: true);
      } else {
        _scheduleAnalysisIfReady();
      }
      return;
    }

    if (!await _audioRecorder.hasPermission()) {
      _showMessage(
        AppLanguage.text(
          'Microphone permission is required',
          'يلزم السماح بالمايكروفون',
        ),
        isError: true,
      );
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = kIsWeb
        ? 'hayat_voice_$timestamp.webm'
        : '${(await getTemporaryDirectory()).path}/hayat_voice_$timestamp.m4a';
    await _audioRecorder.start(
      RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        bitRate: 32000,
        sampleRate: 16000,
      ),
      path: path,
    );
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _clearAnalysis();
    });
  }

  Future<GeminiInlineFile?> _inlineFileFromPath(
    String path, {
    required String mimeType,
    required String fallbackMimeType,
    Uint8List? bytes,
  }) async {
    final trimmedPath = path.trim();
    final lowerPath = trimmedPath.toLowerCase();

    final looksLikeImage = lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.webp') ||
        lowerPath.endsWith('.heic');

    final looksLikeAudio = lowerPath.endsWith('.m4a') ||
        lowerPath.endsWith('.mp3') ||
        lowerPath.endsWith('.wav') ||
        lowerPath.endsWith('.aac') ||
        lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.webm');

    final resolvedMimeType = mimeType.trim().isNotEmpty
        ? mimeType.trim()
        : looksLikeImage
            ? _mimeTypeFromPath(trimmedPath, 'image/jpeg')
            : looksLikeAudio
                ? _mimeTypeFromPath(trimmedPath, fallbackMimeType)
                : fallbackMimeType;

    try {
      final fileBytes = bytes != null && bytes.isNotEmpty
          ? bytes
          : trimmedPath.isNotEmpty
              ? await XFile(trimmedPath).readAsBytes()
              : null;

      if (fileBytes == null || fileBytes.isEmpty) return null;

      return GeminiInlineFile(
        mimeType: resolvedMimeType,
        base64Data: base64Encode(fileBytes),
      );
    } catch (_) {
      throw const GeminiAnalysisException(
        'تعذر قراءة ملف الصورة أو الصوت. اختاري الملف أو سجلي الصوت مرة أخرى.',
      );
    }
  }

    String _mimeTypeFromPath(String path, String fallback) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'm4a' => 'audio/mp4',
      'mp4' => 'audio/mp4',
      'wav' => 'audio/wav',
      'mp3' => 'audio/mpeg',
      'aac' => 'audio/aac',
      'webm' => 'audio/webm',
      _ => fallback,
    };
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'jpg',
        'jpeg',
        'png',
        'webp',
        'heic',
      ],
      withData: true,
    );

    final file = result?.files.single;
    final selectedPath = file?.path;
    final selectedBytes = file?.bytes;
    final fileName = file?.name ?? '';
    final fileExtension = file?.extension?.toLowerCase().trim() ?? '';

    if (!mounted) return;

    if ((selectedPath == null || selectedPath.trim().isEmpty) &&
        (selectedBytes == null || selectedBytes.isEmpty)) {
      return;
    }

    final source = selectedPath?.trim().isNotEmpty == true
        ? selectedPath!.trim()
        : fileName;
    final lowerPath = source.toLowerCase();
    final lowerName = fileName.toLowerCase();
    final imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};

    final isImageFile = imageExtensions.contains(fileExtension) ||
        lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.webp') ||
        lowerPath.endsWith('.heic') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.heic');

    if (isImageFile) {
      Uint8List? previewBytes = selectedBytes;

      if ((previewBytes == null || previewBytes.isEmpty) &&
          selectedPath != null &&
          selectedPath.trim().isNotEmpty) {
        previewBytes = await XFile(selectedPath).readAsBytes();
      }

      if (previewBytes == null || previewBytes.isEmpty) {
        _showMessage(
          AppLanguage.text(
            'Unable to read the selected image. Please choose another image.',
            'تعذر قراءة الصورة المحددة. اختاري صورة أخرى.',
          ),
          isError: true,
        );
        return;
      }

      setState(() {
        _imagePath = selectedPath ?? file!.name;
        _documentPath = '';
        _imagePreviewBytes = previewBytes;
        _imageMimeType = _mimeTypeFromPath(
          fileName.isNotEmpty ? fileName : source,
          'image/jpeg',
        );
        _clearAnalysis();
      });

      _showMessage(
        AppLanguage.text(
          'Photo attached successfully and will be analyzed.',
          'تم إرفاق الصورة بنجاح وسيتم تحليلها.',
        ),
      );
      await _runUserAnalysis(force: true);
      return;
    }

    if (selectedPath == null || selectedPath.trim().isEmpty) {
      _showMessage(
        AppLanguage.text(
          'This document type cannot be attached from web without a local path.',
          'لا يمكن إرفاق هذا المستند من المتصفح بدون مسار ملف محلي.',
        ),
        isError: true,
      );
      return;
    }

    setState(() {
      _documentPath = selectedPath;
      _clearAnalysis();
    });

    _scheduleAnalysisIfReady();
  }

  Future<void> _useCurrentLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage(
        AppLanguage.text(
          'Location permission is required',
          'يلزم السماح بالموقع',
        ),
        isError: true,
      );
      return;
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showMessage(
        AppLanguage.text(
          'Please enable location services',
          'يرجى تفعيل خدمات الموقع',
        ),
        isError: true,
      );
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _locationController.text =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    });
  }

  String _displayableImagePath(GeminiInlineFile? imageFile) {
    if (imageFile != null && imageFile.base64Data.trim().isNotEmpty) {
      return 'data:${imageFile.mimeType};base64,${imageFile.base64Data}';
    }

    final bytes = _imagePreviewBytes;
    if (bytes != null && bytes.isNotEmpty) {
      final mime = _imageMimeType.trim().isNotEmpty
          ? _imageMimeType.trim()
          : 'image/jpeg';
      return 'data:$mime;base64,${base64Encode(bytes)}';
    }

    return _imagePath;
  }

  String _displayableAudioPath(GeminiInlineFile? audioFile) {
    if (audioFile == null) return _audioPath;
    return 'data:${audioFile.mimeType};base64,${audioFile.base64Data}';
  }

  Future<void> _openAudio(String path) async {
    if (path.trim().isEmpty) return;
    if (!await openStoredAudio(path)) {
      _showMessage(
        AppLanguage.text(
          'Unable to open voice recording',
          'تعذر فتح التسجيل الصوتي',
        ),
        isError: true,
      );
    }
  }

  String _attachmentsSummary() {
    final items = [
      if (_imagePath.isNotEmpty) AppLanguage.text('Photo', 'صورة'),
      if (_audioPath.isNotEmpty) AppLanguage.text('Voice', 'صوت'),
      if (_documentPath.isNotEmpty) AppLanguage.text('Document', 'مستند'),
    ];
    return items.isEmpty
        ? AppLanguage.text('No attachments', 'لا توجد مرفقات')
        : items.join('، ');
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _imagePreviewCard({bool compact = false}) {
    final bytes = _imagePreviewBytes;
    if (bytes == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLanguage.text('Selected Photo', 'الصورة المحددة'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              bytes,
              height: compact ? 120 : 190,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (widget.showBackButton) ...[
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    AppLanguage.text('Submit Report', 'إرسال بلاغ'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppLanguage.text(
                          'Required: name, mobile number, and report description',
                          'المطلوب: الاسم ورقم الجوال ووصف البلاغ',
                        ),
                        style: TextStyle(
                          color: Color(0xFF2D3A8C),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label(AppLanguage.text('Full Name *', 'الاسم الكامل *')),
                    _inputField(
                      controller: _nameController,
                      hint: AppLanguage.text(
                        'Enter your full name',
                        'أدخل اسمك الكامل',
                      ),
                      icon: Icons.person_outline,
                      inputFormatters: [
                        _RejectedInputFormatter(
                          allowedPattern: RegExp(r'[A-Za-z\u0600-\u06FF ]'),
                          onRejected: () => _setNameInputMessage(
                            AppLanguage.text(
                              'Text only. Numbers are not allowed.',
                              'فقط المدخلات النصية، لا يمكن إدخال أرقام.',
                            ),
                          ),
                          onAccepted: _clearNameInputMessage,
                        ),
                      ],
                    ),
                    if (_nameInputMessage != null) ...[
                      const SizedBox(height: 6),
                      _fieldErrorText(_nameInputMessage!),
                    ],
                    const SizedBox(height: 16),
                    _label(AppLanguage.text('Mobile Number *', 'رقم الجوال *')),
                    _inputField(
                      controller: _phoneController,
                      hint: AppLanguage.text(
                        'Enter your mobile number',
                        'أدخل رقم الجوال',
                      ),
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        _RejectedInputFormatter(
                          allowedPattern: RegExp(r'\d'),
                          onRejected: () => _setPhoneInputMessage(
                            AppLanguage.text(
                              'Numbers only. Text is not allowed.',
                              'فقط المدخلات الرقمية، لا يمكن إدخال نصوص.',
                            ),
                          ),
                          onAccepted: _clearPhoneInputMessage,
                        ),
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    if (_phoneInputMessage != null) ...[
                      const SizedBox(height: 6),
                      _fieldErrorText(_phoneInputMessage!),
                    ],
                    const SizedBox(height: 16),
                    _label(AppLanguage.text('Description *', 'الوصف *')),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _descController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: AppLanguage.text(
                            'Describe the emergency or issue in detail...',
                            'اكتب وصف البلاغ بالتفصيل...',
                          ),
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        onChanged: (_) {
                          if (_userAnalysis != null ||
                              _analysisMessage != null) {
                            setState(_clearAnalysis);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label(AppLanguage.text('Location *', 'الموقع *')),
                    _inputField(
                      controller: _locationController,
                      hint: AppLanguage.text(
                        'Select or enter location *',
                        'اختر أو أدخل الموقع *',
                      ),
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(
                        Icons.my_location,
                        color: Color(0xFF2D3A8C),
                        size: 18,
                      ),
                      label: Text(
                        AppLanguage.text(
                          'Use current location',
                          'استخدام موقعي الحالي',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF2D3A8C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    _label(AppLanguage.text('Attachments', 'المرفقات')),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _attachmentButton(
                          icon: Icons.camera_alt_outlined,
                          label: _imagePath.isEmpty
                              ? AppLanguage.text('Take Photo', 'تصوير صورة')
                              : _fileName(_imagePath),
                          onTap: _captureImage,
                        ),
                        _attachmentButton(
                          icon: Icons.upload_file_outlined,
                          label: _documentPath.isEmpty
                              ? AppLanguage.text('Upload Document', 'رفع مستند')
                              : _fileName(_documentPath),
                          onTap: _pickDocument,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _voiceRecorderPanel(),
                    if (_imagePreviewBytes != null) ...[
                      const SizedBox(height: 12),
                      _imagePreviewCard(),
                    ],
                    const SizedBox(height: 12),
                    _userAnalysisPanel(),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || _isAnalyzing)
                            ? null
                            : _confirmAndSubmitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3A8C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: (_isSubmitting || _isAnalyzing)
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isAnalyzing
                                        ? AppLanguage.text(
                                            'Analyzing report',
                                            'جاري تحليل البلاغ',
                                          )
                                        : AppLanguage.text(
                                            'Submitting report',
                                            'جاري إرسال البلاغ',
                                          ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _userAnalysis == null
                                    ? AppLanguage.text(
                                        'Analyze and Review',
                                        'تحليل ومراجعة البلاغ',
                                      )
                                    : AppLanguage.text(
                                        'Submit Report',
                                        'تقديم البلاغ',
                                      ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setNameInputMessage(String message) {
    if (_nameInputMessage == message) return;
    setState(() => _nameInputMessage = message);
  }

  void _clearNameInputMessage() {
    if (_nameInputMessage == null) return;
    setState(() => _nameInputMessage = null);
  }

  void _setPhoneInputMessage(String message) {
    if (_phoneInputMessage == message) return;
    setState(() => _phoneInputMessage = message);
  }

  void _clearPhoneInputMessage() {
    if (_phoneInputMessage == null) return;
    setState(() => _phoneInputMessage = null);
  }

  Widget _fieldErrorText(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _attachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final color = isActive ? Colors.red.shade700 : const Color(0xFF2D3A8C);
    return SizedBox(
      width: 240,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: isActive ? Colors.red.shade50 : Colors.white,
          side: BorderSide(color: isActive ? Colors.red.shade200 : Colors.grey),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _userAnalysisPanel() {
    final analysis = _userAnalysis;
    if (_isAnalyzing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF0FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCED4F2)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Color(0xFF2D3A8C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLanguage.text('Analyzing report', 'جاري تحليل البلاغ'),
                style: const TextStyle(
                  color: Color(0xFF2D3A8C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (analysis == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF2D3A8C)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLanguage.text(
                  'Report analysis will appear before submitting the report.',
                  'سيظهر تحليل البلاغ قبل الإرسال.',
                ),
                style: const TextStyle(color: Color(0xFF2D3A8C)),
              ),
            ),
          ],
        ),
      );
    }

    return _analysisSummaryCard(analysis);
  }

  Widget _analysisSummaryCard(GeminiAnalysisResult analysis) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCED4F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF2D3A8C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLanguage.text(
                    'Gemini analysis is ready',
                    'تحليل Gemini جاهز',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF2D3A8C),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (_analysisMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _analysisMessage!,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          _analysisItem(
            AppLanguage.text('Subject', 'الموضوع'),
            analysis.subject,
          ),
          _analysisItem(
            AppLanguage.text('Report type', 'نوع البلاغ'),
            analysis.incidentType,
          ),
          _analysisItem(
            AppLanguage.text('Priority', 'الخطورة'),
            analysis.priority,
          ),
          _analysisItem(
            AppLanguage.text('Smart description', 'الوصف الذكي'),
            analysis.smartDescription,
          ),
          if (analysis.imageAnalysis.trim().isNotEmpty)
            _analysisItem(
              AppLanguage.text('Image analysis', 'تحليل الصورة'),
              analysis.imageAnalysis,
            ),
          if (analysis.audioAnalysis.trim().isNotEmpty)
            _analysisItem(
              AppLanguage.text('Audio analysis', 'تحليل الصوت'),
              analysis.audioAnalysis,
            ),
          _analysisItem(
            AppLanguage.text('AI analysis', 'التحليل العام'),
            analysis.aiAnalysis,
          ),
        ],
      ),
    );
  }

  Widget _analysisItem(String label, String value) {
    final clean = value.trim();
    if (clean.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            clean,
            style: const TextStyle(
              color: Color(0xFF202124),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _voiceRecorderPanel() {
    final hasRecording = _audioPath.isNotEmpty && !_isRecording;
    final statusColor = _isRecording
        ? Colors.red.shade700
        : hasRecording
        ? Colors.green.shade700
        : const Color(0xFF2D3A8C);
    final bgColor = _isRecording
        ? Colors.red.shade50
        : hasRecording
        ? Colors.green.shade50
        : Colors.white;
    final borderColor = _isRecording
        ? Colors.red.shade300
        : hasRecording
        ? Colors.green.shade300
        : const Color(0xFFCED4F2);
    final statusText = _isRecording
        ? AppLanguage.text('Recording now', 'يتم التسجيل الآن')
        : hasRecording
        ? AppLanguage.text('Saved voice recording', 'تم حفظ التسجيل الصوتي')
        : AppLanguage.text('Ready to record voice', 'جاهز لتسجيل الصوت');
    final buttonText = _isRecording
        ? AppLanguage.text('Stop and save voice', 'إيقاف وحفظ الصوت')
        : hasRecording
        ? AppLanguage.text('Record again', 'تسجيل من جديد')
        : AppLanguage.text('Start recording', 'بدء التسجيل');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording
                      ? Icons.fiber_manual_record
                      : hasRecording
                      ? Icons.check_rounded
                      : Icons.mic_none_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLanguage.text('Voice recording', 'تسجيل الصوت'),
                      style: const TextStyle(
                        color: Color(0xFF2D3A8C),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _isRecording
                      ? Icons.radio_button_checked
                      : hasRecording
                      ? Icons.task_alt
                      : Icons.info_outline,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isRecording
                        ? AppLanguage.text(
                            'Press stop when you finish speaking.',
                            'اضغطي إيقاف عند الانتهاء من الكلام.',
                          )
                        : hasRecording
                        ? _fileName(_audioPath)
                        : AppLanguage.text(
                            'Report analysis will appear before submitting the report.',
                            'سيظهر تحليل البلاغ قبل الإرسال.',
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          if (hasRecording) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _openAudio(_audioPath),
                icon: const Icon(Icons.play_circle_outline),
                label: Text(
                  AppLanguage.text('Listen to recording', 'استماع للتسجيل'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D3A8C),
                  side: const BorderSide(color: Color(0xFF2D3A8C)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing || _isSubmitting
                  ? null
                  : _toggleRecording,
              icon: Icon(
                _isRecording
                    ? Icons.stop_circle_outlined
                    : Icons.mic_none_rounded,
              ),
              label: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording
                    ? Colors.red.shade700
                    : const Color(0xFF2D3A8C),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }
}

class _RejectedInputFormatter extends TextInputFormatter {
  const _RejectedInputFormatter({
    required this.allowedPattern,
    required this.onRejected,
    required this.onAccepted,
  });

  final RegExp allowedPattern;
  final VoidCallback onRejected;
  final VoidCallback onAccepted;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    var rejected = false;
    for (final rune in newValue.text.runes) {
      final char = String.fromCharCode(rune);
      if (allowedPattern.hasMatch(char)) {
        buffer.write(char);
      } else {
        rejected = true;
      }
    }

    if (rejected) {
      onRejected();
      final filtered = buffer.toString();
      return TextEditingValue(
        text: filtered,
        selection: TextSelection.collapsed(offset: filtered.length),
      );
    }

    onAccepted();
    return newValue;
  }
}
