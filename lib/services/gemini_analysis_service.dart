import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class GeminiAnalysisResult {
  const GeminiAnalysisResult({
    required this.subject,
    required this.incidentType,
    required this.smartDescription,
    required this.aiAnalysis,
    required this.imageAnalysis,
    required this.audioAnalysis,
    required this.priority,
  });

  final String subject;
  final String incidentType;
  final String smartDescription;
  final String aiAnalysis;
  final String imageAnalysis;
  final String audioAnalysis;
  final String priority;
}

class GeminiInlineFile {
  const GeminiInlineFile({required this.mimeType, required this.base64Data});

  final String mimeType;
  final String base64Data;
}

class GeminiAnalysisService {
  Future<GeminiAnalysisResult> analyzeReport({
    required String description,
    required String reporterName,
    required String reporterPhone,
    required String location,
    required String languageCode,
    GeminiInlineFile? imageFile,
    GeminiInlineFile? audioFile,
  }) async {
    final apiKey = ApiService.normalizedGeminiApiKey;
    if (apiKey.isEmpty) {
      throw const GeminiAnalysisException(
        'مفتاح Gemini غير مضاف. شغلي التطبيق مع --dart-define=GEMINI_API_KEY=YOUR_KEY',
      );
    }

    final isArabic = languageCode == 'ar';

    final prompt = isArabic
        ? '''
حلل بلاغ طوارئ لمنصة حياة وأرجع JSON فقط بدون Markdown.

مهم جداً:
- كل القيم النصية يجب أن تكون بالعربية.
- يجب أن تكون subject و incident_type و smart_description و ai_analysis و image_analysis و audio_analysis و priority كلها بالعربية فقط.
- إذا كان وصف المستخدم أو المرفق بلغة مختلفة عن لغة التطبيق، ترجم الناتج النهائي إلى العربية.
- إذا كان هناك صوت مرفق، فرّغ الصوت كنص واضح داخل audio_analysis باللغة العربية، ولا تكتفِ بعبارة عامة.
- إذا كان الصوت غير واضح، اكتب أن الصوت غير واضح ثم استنتج ما يمكن من سياق البلاغ.
- إذا كان هناك صورة مرفقة، حلل محتواها بصرياً داخل image_analysis باللغة العربية، ولا تكتفِ بعبارة عامة.
- إذا كانت الصورة مرفقة كملف صورة، تعامل معها كصورة بلاغ أساسية وليست كمستند عادي.
- إذا كانت الصورة مرفقة، يجب تحليلها فعلياً بصرياً وكتابة نتيجة واضحة ومحددة في image_analysis.
- استنتج نوع البلاغ والخطورة من الوصف والصورة والصوت معاً.

المفاتيح المطلوبة:
subject: موضوع مختصر وواضح للبلاغ بالعربية، ويجب أن يصف الحادث بدقة وليس عبارة عامة.
incident_type: نوع البلاغ، اختر نوعاً أو أكثر من: حريق، حادث، صيانة طرق، كوارث طبيعية، انهيار مبنى، طوارئ بيئية، أخرى.
smart_description: وصف ذكي موحد ومفصل يجمع وصف المستخدم مع دلالات الصورة والصوت إن وجدت، ويذكر المكان والخطر الظاهر والنتيجة المتوقعة، ولا يقل عن جملتين إذا كانت البيانات كافية.
ai_analysis: تحليل شامل ودقيق للبلاغ بالعربية، لا يكون مختصراً جداً. يجب أن يكون منظماً في نقاط واضحة ويتضمن:
- ملخص الحالة.
- الأدلة المستنتجة من الوصف والصورة والصوت، مع التفريق بين المؤكد والمحتمل.
- مستوى الخطورة وسبب اختياره بناءً على قواعد الخطورة.
- جهة الإحالة المقترحة من: الدفاع المدني، الشرطة، الهلال الأحمر، المرور، وزارة البيئة، أمانة المدينة.
- سبب اختيار جهة الإحالة.
- إذا كانت الحالة تحتاج أكثر من جهة، اذكر جميع الجهات المطلوبة وسبب كل جهة.
- الإجراء العاجل المقترح للضابط أو فريق الاستجابة.
- ملاحظات مهمة للضابط قبل التعامل مع البلاغ.
image_analysis: تحليل الصورة إن وجدت، مع وصف ما يظهر فيها مثل دخان/نار/مركبات/أضرار/تلوث/إصابات/طريق، أو نص فارغ فقط إذا لم توجد صورة.
audio_analysis: تفريغ نصي واضح للصوت إن وجد مع تحليل مختصر لدلالته، أو نص فارغ إذا لم يوجد صوت.
priority: واحدة فقط من: منخفضة، متوسطة، عالية، حرجة.

قواعد تحديد الخطورة:
- حرجة: وجود حريق نشط أو دخان كثيف، إصابات خطيرة أو أشخاص عالقين، انهيار مبنى، غرق، تسرب غاز أو مادة خطرة، خطر مباشر على الأرواح، أو كارثة بيئية كبيرة. يجب إحالتها فوراً للجهة المختصة وقد تتطلب أكثر من جهة.
- عالية: خطر واضح يحتاج تدخل سريع مثل حادث قوي، انسداد طريق خطر، تلوث بيئي ظاهر، إصابات محتملة، ضرر متصاعد، أو حريق محدود قابل للانتشار.
- متوسطة: حالة تحتاج متابعة ميدانية لكنها لا تظهر خطراً مباشراً على الأرواح، مثل أضرار طرق أو بلاغ يحتاج تحقق.
- منخفضة: بلاغ بسيط أو ملاحظة لا تتطلب تدخل عاجل.

قواعد جهة الإحالة المقترحة:
- الدفاع المدني: حرائق، دخان، انهيارات، إنقاذ، تسرب غاز، خطر سلامة مباشر.
- المرور: حوادث مركبات، ازدحام، إغلاق طريق بسبب حادث، خطر مروري.
- الهلال الأحمر: إصابات، حالات صحية، أشخاص مصابون أو بحاجة إسعاف.
- الشرطة: اشتباه جنائي، تجمهر خطير، اعتداء، تهديد أمني، أو تنظيم موقع حادث عند الحاجة.
- وزارة البيئة: تلوث، تسرب مواد، نفوق، روائح كيميائية، طوارئ بيئية.
- أمانة المدينة: حفر، إنارة، نظافة، صيانة طرق، عوائق بلدية، أضرار بنية تحتية غير طارئة.
إذا كان البلاغ يحتاج أكثر من جهة، اذكر الجهات كلها داخل ai_analysis مع سبب كل جهة.

بيانات البلاغ:
الوصف: $description
الموقع: $location
اسم المبلغ: $reporterName
رقم المبلغ: $reporterPhone
'''
        : '''
Analyze an emergency report for Hayat platform and return JSON only without Markdown.

Very important:
- All text values must be in English.
- subject, incident_type, smart_description, ai_analysis, image_analysis, audio_analysis, and priority must all be in English only.
- If the user description or attachment is in a different language than the app language, translate the final output into English.
- If audio is attached, transcribe the audio clearly into audio_analysis in English, and do not use a generic sentence.
- If the audio is unclear, say that the audio is unclear, then infer what you can from the report context.
- If an image is attached, visually analyze its content into image_analysis in English, and do not use a generic sentence.
- If the image is attached as an image file, treat it as the main report image, not as a normal document.
- If an image is attached, you must visually analyze it and write a clear, specific result in image_analysis.
- Infer the report type and severity from the description, image, and audio together.

Required keys:
subject: short clear report subject in English. It must describe the incident accurately and must not be generic.
incident_type: report type, choose one or more from: Fire, Accident, Road Maintenance, Natural Disaster, Building Collapse, Environmental Emergency, Other.
smart_description: detailed unified smart description combining the user description with image/audio evidence if available. Mention the location, visible risk, and likely consequence. Use at least two sentences when enough information exists.
ai_analysis: detailed and accurate report analysis in English. Do not make it too short. It must be organized in clear points and include:
- Case summary.
- Evidence inferred from the description, image, and audio, distinguishing confirmed facts from possible assumptions.
- Severity level and why it was selected based on the severity rules.
- Recommended referral department from: Civil Defense, Police, Red Crescent, Traffic, Ministry of Environment, Municipality.
- Reason for choosing the referral department.
- If the case needs more than one department, mention all required departments and the reason for each one.
- Recommended urgent action for the officer or response team.
- Important notes for the officer before handling the report.
image_analysis: image analysis if an image exists, describing visible smoke/fire/vehicles/damage/pollution/injuries/road condition, or empty string only if no image exists.
audio_analysis: clear audio transcription if audio exists with a brief interpretation of its relevance, or empty string if no audio exists.
priority: exactly one of: Low, Medium, High, Critical.

Severity rules:
- Critical: active fire or heavy smoke, severe injuries or trapped people, building collapse, drowning, gas or hazardous material leak, immediate life risk, or major environmental disaster. It must be referred immediately to the relevant department and may require multiple departments.
- High: clear risk requiring fast response, serious accident, dangerous road blockage, visible pollution, possible injuries, escalating damage, or limited fire that may spread.
- Medium: needs field follow-up but no immediate life-threatening danger, such as road damage or a report requiring verification.
- Low: minor report or observation that does not require urgent intervention.

Recommended referral department rules:
- Civil Defense: fires, smoke, collapses, rescue, gas leaks, direct safety risk.
- Traffic: vehicle accidents, congestion, road closure due to accident, traffic hazard.
- Red Crescent: injuries, medical cases, injured people, or need for ambulance.
- Police: suspected criminal activity, dangerous crowding, assault, security threat, or scene control when needed.
- Ministry of Environment: pollution, material leaks, animal death, chemical odors, environmental emergencies.
- Municipality: potholes, lighting, cleaning, road maintenance, municipal obstacles, non-urgent infrastructure damage.
If the report needs more than one department, mention all relevant departments inside ai_analysis with the reason for each one.

Report data:
Description: $description
Location: $location
Reporter name: $reporterName
Reporter phone: $reporterPhone
''';

    final parts = <Map<String, dynamic>>[
      {'text': prompt},
      if (imageFile != null)
        {
          'inline_data': {
            'mime_type': imageFile.mimeType,
            'data': imageFile.base64Data,
          },
        },
      if (audioFile != null)
        {
          'inline_data': {
            'mime_type': audioFile.mimeType,
            'data': audioFile.base64Data,
          },
        },
    ];

    try {
      final response = await _postWithAvailableModel(parts, apiKey);

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List?;
      final firstCandidate = candidates == null || candidates.isEmpty
          ? null
          : candidates.first as Map<String, dynamic>?;
      final responseParts =
          (firstCandidate?['content'] as Map<String, dynamic>?)?['parts']
              as List?;
      final text =
          responseParts
              ?.map((part) => (part as Map)['text']?.toString() ?? '')
              .join()
              .trim() ??
          '';
      if (text.isEmpty) {
        throw const GeminiAnalysisException('رجع Gemini نتيجة فارغة');
      }
      final data = _decodeJsonObject(text);

      final imageAnalysis = data['image_analysis']?.toString().trim() ?? '';
      final audioAnalysis = data['audio_analysis']?.toString().trim() ?? '';
      return GeminiAnalysisResult(
        subject:
            data['subject']?.toString().trim().ifEmpty(null) ??
            _buildFallbackSubject(description),
        incidentType: _normalizeIncidentType(
          data['incident_type'],
          isArabic: isArabic,
        ),
        smartDescription:
            data['smart_description']?.toString().trim().ifEmpty(null) ??
            description,
        aiAnalysis:
            data['ai_analysis']?.toString().trim().ifEmpty(null) ?? text,
        imageAnalysis: imageAnalysis.isNotEmpty || imageFile == null
            ? imageAnalysis
            : isArabic
                ? 'تم تحليل الصورة ضمن الوصف الذكي والتحليل الشامل.'
                : 'The image was analyzed as part of the smart description and overall analysis.',
        audioAnalysis: audioAnalysis.isNotEmpty || audioFile == null
            ? audioAnalysis
            : isArabic
                ? 'تم تحليل الصوت ضمن الوصف الذكي والتحليل الشامل.'
                : 'The audio was analyzed as part of the smart description and overall analysis.',
        priority: _normalizePriority(
          data['priority']?.toString() ?? (isArabic ? 'متوسطة' : 'Medium'),
          isArabic: isArabic,
        ),
      );
    } on GeminiAnalysisException {
      rethrow;
    } catch (error) {
      throw GeminiAnalysisException('تعذر تحليل Gemini: $error');
    }
  }

  Future<String> translateStoredText({
    required String text,
    required String languageCode,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return cleanText;

    final apiKey = ApiService.normalizedGeminiApiKey;
    if (apiKey.isEmpty) return cleanText;

    final isArabic = languageCode == 'ar';
    final prompt = isArabic
        ? '''
ترجم النص التالي إلى العربية فقط وأرجع JSON فقط بدون Markdown.

مهم:
- أرجع كائن JSON فقط بالشكل التالي: {"translation":"النص المترجم"}
- لا تضف شرحاً أو مقدمات.
- حافظ على المعنى والسياق الخاص ببلاغ الطوارئ.
- إذا كان النص عربياً بالفعل، أعده كما هو داخل قيمة translation.

النص:
$cleanText
'''
        : '''
Translate the following text into English only and return JSON only without Markdown.

Important:
- Return a JSON object only in this exact shape: {"translation":"translated text"}
- Do not add explanations or introductions.
- Preserve the meaning and emergency-report context.
- If the text is already English, return it as-is inside the translation value.

Text:
$cleanText
''';

    try {
      final response = await _postWithAvailableModel(
        [
          {'text': prompt},
        ],
        apiKey,
      );
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List?;
      final firstCandidate = candidates == null || candidates.isEmpty
          ? null
          : candidates.first as Map<String, dynamic>?;
      final responseParts =
          (firstCandidate?['content'] as Map<String, dynamic>?)?['parts']
              as List?;
      final rawText =
          responseParts
              ?.map((part) => (part as Map)['text']?.toString() ?? '')
              .join()
              .trim() ??
          '';
      if (rawText.isEmpty) return cleanText;

      try {
        final translatedJson = _decodeJsonObject(rawText);
        final translated = translatedJson['translation']?.toString().trim() ?? '';
        return translated.isEmpty ? cleanText : translated;
      } catch (_) {
        return rawText;
      }
    } catch (_) {
      return cleanText;
    }
  }

  Future<http.Response> _postWithAvailableModel(
    List<Map<String, dynamic>> parts,
    String apiKey,
  ) async {
    final models = <String>[
      ApiService.geminiModel,
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-flash-latest',
    ].where((model) => model.trim().isNotEmpty).toSet();

    String lastMessage = '';
    for (final model in models) {
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$model:generateContent',
        {'key': apiKey},
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {'role': 'user', 'parts': parts},
          ],
          'generationConfig': {
            'temperature': 0.2,
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      lastMessage = _extractServerError(response.body);
      final retryable =
          response.statusCode == 404 ||
          response.statusCode == 429 ||
          response.statusCode == 503;
      if (!retryable) break;
    }

    throw GeminiAnalysisException(
      lastMessage.isEmpty
          ? 'تعذر تحليل Gemini'
          : 'تعذر تحليل Gemini: $lastMessage',
    );
  }

  static Map<String, dynamic> _decodeJsonObject(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
        .trim();
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return {
        'subject': '',
        'incident_type': 'أخرى',
        'smart_description': '',
        'ai_analysis': value,
        'image_analysis': '',
        'audio_analysis': '',
        'priority': 'متوسطة',
      };
    }
    return const {};
  }

  static String _extractServerError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] != null) {
          return error['message'].toString();
        }
      }
    } catch (_) {
      return '';
    }
    return '';
  }

  static String _normalizePriority(String value, {required bool isArabic}) {
    final lower = value.toLowerCase();

    if (value.contains('حرج') || lower.contains('critical')) {
      return isArabic ? 'حرجة' : 'Critical';
    }
    if (value.contains('عال') || lower.contains('high')) {
      return isArabic ? 'عالية' : 'High';
    }
    if (value.contains('منخفض') || lower.contains('low')) {
      return isArabic ? 'منخفضة' : 'Low';
    }
    return isArabic ? 'متوسطة' : 'Medium';
  }

  static String _normalizeIncidentType(
    dynamic value, {
    required bool isArabic,
  }) {
    final raw = value is List
        ? value.map((item) => item.toString()).join(',')
        : value?.toString() ?? '';
    final lower = raw.toLowerCase();

    final pairs = <String, String>{
      'حريق': 'Fire',
      'حادث': 'Accident',
      'صيانة طرق': 'Road Maintenance',
      'كوارث طبيعية': 'Natural Disaster',
      'انهيار مبنى': 'Building Collapse',
      'طوارئ بيئية': 'Environmental Emergency',
      'أخرى': 'Other',
    };

    final selectedArabic = <String>[];

    void addIfMatch(String ar, String en, List<String> keywords) {
      if (raw.contains(ar) ||
          lower.contains(en.toLowerCase()) ||
          keywords.any((k) => lower.contains(k.toLowerCase()))) {
        selectedArabic.add(ar);
      }
    }

    addIfMatch('حريق', 'Fire', ['smoke', 'burning']);
    addIfMatch('حادث', 'Accident', ['crash', 'collision']);
    addIfMatch('صيانة طرق', 'Road Maintenance', ['road', 'pothole']);
    addIfMatch('كوارث طبيعية', 'Natural Disaster', [
      'flood',
      'storm',
      'earthquake',
    ]);
    addIfMatch('انهيار مبنى', 'Building Collapse', ['collapse', 'building']);
    addIfMatch('طوارئ بيئية', 'Environmental Emergency', [
      'environment',
      'pollution',
      'leak',
      'spill',
      'chemical',
    ]);

    final unique = selectedArabic.toSet().toList();

    if (unique.isEmpty) {
      return isArabic ? 'أخرى' : 'Other';
    }

    return unique.map((ar) => isArabic ? ar : pairs[ar]!).join(', ');
  }

  static String _buildFallbackSubject(String description) {
    final clean = description.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return 'بلاغ جديد';
    return clean.length <= 42 ? clean : '${clean.substring(0, 42)}...';
  }
}

class GeminiAnalysisException implements Exception {
  const GeminiAnalysisException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension on String {
  String? ifEmpty(String? fallback) => isEmpty ? fallback : this;
}
