import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../services/api_service.dart';

class SmartReportScreen extends StatefulWidget {
  const SmartReportScreen({super.key});

  @override
  State<SmartReportScreen> createState() => _SmartReportScreenState();
}

class _SmartReportScreenState extends State<SmartReportScreen> {
  late final WebViewController controller;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _ensureWebViewPlatform();

    controller = WebViewController.fromPlatformCreationParams(_creationParams)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _loadError = null;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) => setState(() {
            _isLoading = false;
            _loadError =
                'تعذر فتح صفحة البلاغ الذكي داخل التطبيق. تأكدي أن Streamlit شغال وأن SMART_REPORT_WEB_URL صحيح.';
          }),
        ),
      );

    _requestPermissions();
    controller.loadRequest(Uri.parse(ApiService.smartReportWebUrl));
  }

  void _ensureWebViewPlatform() {
    if (kIsWeb || WebViewPlatform.instance != null) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        WebViewPlatform.instance = AndroidWebViewPlatform();
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        WebViewPlatform.instance = WebKitWebViewPlatform();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
    }
  }

  PlatformWebViewControllerCreationParams get _creationParams {
    if (!kIsWeb && WebViewPlatform.instance is WebKitWebViewPlatform) {
      return WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    }
    return const PlatformWebViewControllerCreationParams();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
      Permission.locationWhenInUse,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart AI Report')),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_loadError != null)
            Container(
              color: const Color(0xFFF5F6FA),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
