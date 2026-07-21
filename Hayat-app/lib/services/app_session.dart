import 'package:flutter/foundation.dart';

enum AppRole { user, officer }

class AppSession {
  static final ValueNotifier<AppRole?> role = ValueNotifier<AppRole?>(null);
}
