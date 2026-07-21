import 'package:flutter/material.dart';
import '../../services/app_language.dart';
import '../../services/officer_auth_store.dart';
import '../officer/officer_dashboard.dart';

class OfficerLoginScreen extends StatefulWidget {
  const OfficerLoginScreen({super.key});

  @override
  State<OfficerLoginScreen> createState() => _OfficerLoginScreenState();
}

class _OfficerLoginScreenState extends State<OfficerLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _errorMessage;

  bool get _isEnglish => !AppLanguage.isArabic;

  String _t(String ar, String en) => _isEnglish ? en : ar;

  String? _findOfficerUsername(String identifier) {
    return OfficerAuthStore.findUsername(identifier);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final identifier = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage = _t(
          'يرجى إدخال اسم المستخدم أو رقم الهوية وكلمة المرور',
          'Please enter your username or ID number and password',
        ),
      );
      return;
    }

    final username = _findOfficerUsername(identifier);
    if (username == null || !OfficerAuthStore.verify(identifier, password)) {
      setState(
        () => _errorMessage = _t(
          'اسم المستخدم أو رقم الهوية أو كلمة المرور غير صحيحة',
          'Username, ID number, or password is incorrect',
        ),
      );
      return;
    }

    setState(() => _errorMessage = null);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OfficerDashboard(
          initialPassword: password,
          officerUsername: username,
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    int step = 1;
    String? verifiedUsername;
    final usernameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDS) => Directionality(
          textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(n: 1, active: step >= 1, done: step > 1),
                    Container(
                      width: 40,
                      height: 2,
                      color: step > 1
                          ? const Color(0xFFB41727)
                          : Colors.grey[300],
                    ),
                    _StepDot(n: 2, active: step >= 2, done: false),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  step == 1
                      ? _t('التحقق من الهوية', 'Identity Verification')
                      : _t('كلمة المرور الجديدة', 'New Password'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  step == 1
                      ? _t(
                          'أدخل اسم المستخدم ورقم هويتك',
                          'Enter your username and ID number',
                        )
                      : _t(
                          'أدخل كلمة المرور الجديدة',
                          'Enter your new password',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: step == 1
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Field(
                          controller: usernameCtrl,
                          label: _t('اسم المستخدم', 'Username'),
                          icon: Icons.person_outline,
                          isEnglish: _isEnglish,
                        ),
                        const SizedBox(height: 15),
                        _Field(
                          controller: idCtrl,
                          label: _t('رقم الهوية الوطنية', 'National ID Number'),
                          icon: Icons.badge_outlined,
                          numeric: true,
                          isEnglish: _isEnglish,
                        ),
                        if (dialogError != null) ...[
                          const SizedBox(height: 12),
                          _ErrorBox(
                            message: dialogError!,
                            isEnglish: _isEnglish,
                          ),
                        ],
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Field(
                          controller: newPassCtrl,
                          label: _t('كلمة المرور الجديدة', 'New Password'),
                          icon: Icons.lock_outline,
                          obscure: obscureNew,
                          onToggle: () => setDS(() => obscureNew = !obscureNew),
                          isEnglish: _isEnglish,
                        ),
                        const SizedBox(height: 15),
                        _Field(
                          controller: confirmCtrl,
                          label: _t('تأكيد كلمة المرور', 'Confirm Password'),
                          icon: Icons.lock_outline,
                          obscure: obscureConfirm,
                          onToggle: () =>
                              setDS(() => obscureConfirm = !obscureConfirm),
                          isEnglish: _isEnglish,
                        ),
                        if (dialogError != null) ...[
                          const SizedBox(height: 12),
                          _ErrorBox(
                            message: dialogError!,
                            isEnglish: _isEnglish,
                          ),
                        ],
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _t('إلغاء', 'Cancel'),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB41727),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (step == 1) {
                    final u = usernameCtrl.text.trim();
                    final id = idCtrl.text.trim();
                    if (u.isEmpty || id.isEmpty) {
                      setDS(
                        () => dialogError = _t(
                          'يرجى ملء جميع الحقول',
                          'Please fill in all fields',
                        ),
                      );
                      return;
                    }
                    final officer = OfficerAuthStore.officers[u];
                    if (officer == null || officer['id'] != id) {
                      setDS(
                        () => dialogError = _t(
                          'اسم المستخدم أو رقم الهوية غير صحيح',
                          'Username or ID number is incorrect',
                        ),
                      );
                      return;
                    }
                    verifiedUsername = u;
                    setDS(() {
                      step = 2;
                      dialogError = null;
                    });
                  } else {
                    final np = newPassCtrl.text.trim();
                    final cp = confirmCtrl.text.trim();
                    if (np.isEmpty || cp.isEmpty) {
                      setDS(
                        () => dialogError = _t(
                          'يرجى ملء جميع الحقول',
                          'Please fill in all fields',
                        ),
                      );
                      return;
                    }
                    if (np.length < 6) {
                      setDS(
                        () => dialogError = _t(
                          'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                          'Password must be at least 6 characters',
                        ),
                      );
                      return;
                    }
                    if (np != cp) {
                      setDS(
                        () => dialogError = _t(
                          'كلمتا المرور غير متطابقتين',
                          'Passwords do not match',
                        ),
                      );
                      return;
                    }
                    await OfficerAuthStore.resetPassword(
                      username: verifiedUsername!,
                      id: idCtrl.text.trim(),
                      newPassword: np,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _t(
                            'تم تغيير كلمة المرور بنجاح',
                            'Password changed successfully',
                          ),
                          textAlign: _isEnglish
                              ? TextAlign.left
                              : TextAlign.right,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: Colors.green[700],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  step == 1 ? _t('تحقق', 'Verify') : _t('تأكيد', 'Confirm'),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        icon: Icon(
                          _isEnglish
                              ? Icons.arrow_back_ios
                              : Icons.arrow_forward_ios,
                          size: 15,
                          color: const Color(0xFFB41727),
                        ),
                        label: Text(
                          _t('رجوع', 'Back'),
                          style: const TextStyle(
                            color: Color(0xFFB41727),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            AppLanguage.toggle();
                            _errorMessage = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFFB41727,
                              ).withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isEnglish ? 'SA' : 'EN',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isEnglish ? 'العربية' : 'English',
                                style: const TextStyle(
                                  color: Color(0xFFB41727),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _t(
                              'البوابة الرسمية للموظفين',
                              'Official Employee Portal',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _t('المملكة العربية السعودية', 'Saudi Arabia'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFB41727),
                            width: 2.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/hayat.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.shield,
                                    color: Color(0xFFB41727),
                                    size: 40,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _t('منصة حياة', 'Hayat Platform'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB41727),
                        ),
                      ),
                      const Text(
                        'Hayat Platform',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),
                      Text(
                        _t('تسجيل دخول الضابط', 'Officer Login'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      _Field(
                        controller: _usernameController,
                        label: _t(
                          'اسم المستخدم أو رقم الهوية',
                          'Username or ID Number',
                        ),
                        icon: Icons.person_outline,
                        isEnglish: _isEnglish,
                      ),
                      const SizedBox(height: 20),
                      _Field(
                        controller: _passwordController,
                        label: _t('كلمة المرور', 'Password'),
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        onToggle: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        isEnglish: _isEnglish,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        _ErrorBox(
                          message: _errorMessage!,
                          isEnglish: _isEnglish,
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB41727),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _t('تسجيل الدخول', 'Login'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          _t('نسيت كلمة المرور؟', 'Forgot Password?'),
                          style: const TextStyle(
                            color: Color(0xFFB41727),
                            fontSize: 13,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int n;
  final bool active;
  final bool done;
  const _StepDot({required this.n, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFFB41727) : Colors.grey[300],
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '$n',
                style: TextStyle(
                  color: active ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isEnglish;
  final bool obscure;
  final bool numeric;
  final VoidCallback? onToggle;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.isEnglish = false,
    this.obscure = false,
    this.numeric = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: isEnglish ? TextAlign.left : TextAlign.right,
      obscureText: obscure,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: onToggle,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final bool isEnglish;
  const _ErrorBox({required this.message, this.isEnglish = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
              textAlign: isEnglish ? TextAlign.left : TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
