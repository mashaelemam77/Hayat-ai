import 'package:flutter/material.dart';
import '../../services/app_language.dart';

class FirstAidPage extends StatelessWidget {
  const FirstAidPage({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 25),
            decoration: const BoxDecoration(
              color: Color(0xFF2D3A8C),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              children: [
                if (showBackButton) ...[
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: _circleIcon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                ],
                _circleIcon(Icons.favorite),
                const SizedBox(width: 12),
                Text(
                  AppLanguage.text("First Aid Tips", "إرشادات الإسعافات"),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _aidCard(
                  Icons.phone,
                  const Color.fromARGB(255, 77, 95, 209),
                  "Emergency Hotline",
                  AppLanguage.text(
                    "Call for immediate assistance",
                    "اتصل للمساعدة العاجلة",
                  ),
                  highlighted: true,
                ),
                _aidCard(
                  Icons.favorite,
                  const Color(0xFF2D3A8C),
                  "CPR",
                  AppLanguage.text(
                    "Call emergency services first. Push hard and fast in the center of the chest. Allow full chest recoil between compressions. Continue until help arrives.",
                    "اتصل بالطوارئ أولاً. اضغط بقوة وبسرعة في منتصف الصدر واستمر حتى وصول المساعدة.",
                  ),
                ),
                _aidCard(
                  Icons.local_fire_department,
                  Colors.orange,
                  "Burns",
                  AppLanguage.text(
                    "Cool the burn under running water for at least 10 minutes. Cover with a sterile bandage. Do not apply ice directly. Seek medical help for severe burns.",
                    "برّد الحرق بالماء الجاري 10 دقائق على الأقل، وغطّه بضماد نظيف. لا تضع الثلج مباشرة.",
                  ),
                ),
                _aidCard(
                  Icons.water_drop,
                  const Color(0xFF2D3A8C),
                  "Bleeding",
                  AppLanguage.text(
                    "Apply firm pressure with a clean cloth. Elevate the wound above heart level if possible. Do not remove the cloth if blood soaks through, add more layers.",
                    "اضغط على الجرح بقطعة قماش نظيفة وارفعه إن أمكن. أضف طبقات إذا امتلأت القماشة بالدم.",
                  ),
                ),
                _aidCard(
                  Icons.content_cut,
                  const Color(0xFF9B4DFF),
                  "Cuts",
                  AppLanguage.text(
                    "Clean the wound with water. Apply antibiotic ointment. Cover with a bandage. Change bandage daily. Watch for signs of infection like redness or swelling.",
                    "نظف الجرح بالماء وغطّه بضماد وغيّره يومياً. راقب الاحمرار أو التورم.",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _circleIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  static Widget _aidCard(
    IconData icon,
    Color iconColor,
    String title,
    String subtitle, {
    bool highlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFEEF0FB) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
