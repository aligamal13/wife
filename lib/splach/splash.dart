

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wife_flutter/splach/code.dart';
import 'package:wife_flutter/stations.dart';

class SplashScreenAds extends StatefulWidget {
  @override
  _SplashScreenAdsState createState() => _SplashScreenAdsState();
}

class _SplashScreenAdsState extends State<SplashScreenAds>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // ✅ الإضافات الجديدة بالضبط زي كود SplashScreen
  String _deviceId = 'Loading...';
  Timer? _timer;
  DateTime? _expiryDate;
  String _status = 'جارٍ التحقق...';
  bool _isExpired = false;
  Duration _remaining = Duration.zero;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();

    // ✅ كود SplashScreen الأصلي
    _loadOnboardingState();
    _loadDeviceId();

    // الاشتراك في موضوع الإعلانات
    FirebaseMessaging.instance.subscribeToTopic("NotificationWife");

    // ✅ استدعاء تفعيل الرخصة في الخلفية (بدون تغيير باقي الكود)
    getDeviceId();
    checkLicenseStatus();

    // إعداد الأنيميشن
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();


  }

  // ✅ كل كود SplashScreen الإضافي 👇

  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFirstTime = prefs.getBool('has_seen_onboarding') ?? true;
    });
  }

  Future<void> _saveOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', false);
  }

  Future<void> _loadDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }

    setState(() {
      _deviceId = deviceId;
    });

    _checkSubscription(deviceId);
  }

  Future<void> _checkSubscription(String deviceId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('activated_devices')
          .doc(deviceId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _status = data['status'] ?? 'active';
            if (data['expiry_date'] != null) {
              _expiryDate = (data['expiry_date'] as Timestamp).toDate();
            }
          });

          if (_status == 'active' &&
              _expiryDate != null &&
              DateTime.now().isBefore(_expiryDate!)) {
            _navigateToSubscribedPage();
          } else {
            _handleBlocked('انتهت فترة الاشتراك.');
          }
        } else {
          _startTrialPeriod();
        }
      } else {
        _startTrialPeriod();
      }
    } catch (e) {
      print('Error checking subscription: $e');
      // _handleBlocked('خطأ في الاتصال بالخادم.');
      _startTrialPeriod();

    }
  }

  Future<void> _startTrialPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final storedExpiry = prefs.getString('trial_expiry');

    if (storedExpiry != null) {
      _expiryDate = DateTime.tryParse(storedExpiry);
    }

    // حط هنا اليوم او الواقت الانتهاء التجربه
    if (_expiryDate == null) {
      _expiryDate = DateTime.now().add(Duration(days: 7));
      await prefs.setString('trial_expiry', _expiryDate!.toIso8601String());
    }

    _startTimer();
  }

  void _navigateToSubscribedPage() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          // الانتقال للصفحة الرئيسية بعد 3 ثواني
          MaterialPageRoute(builder: (context) => FirstPage()), //Subscrption
        );
      }
    });


  }

  void _navigateToTrialPage() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          // الانتقال للصفحة الرئيسية بعد 3 ثواني
          MaterialPageRoute(builder: (context) => FirstPage()), //Subscrption
        );
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_expiryDate != null) {
        final now = DateTime.now();
        if (now.isAfter(_expiryDate!)) {
          _handleBlocked('انتهت فترة التجربة.');
        } else {
          setState(() {
            _remaining = _expiryDate!.difference(now);
          });

          if (_remaining.inSeconds > 0) {
            _navigateToTrialPage();
          }
        }
      }
    });
  }

  void _handleBlocked(String message) {
    if (!_isExpired) {
      _isExpired = true;
      _showBlockedDialog(message);
    }
  }

  void _showBlockedDialog(String message) {
    final whatsappUrl =
        "https://wa.me/+201153562128?text=أحتاج%20تجديد%20الاشتراك%20لجهازي%20مع%20المعرف%20التالي:%20\n$_deviceId";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Warning
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 30),
                    SizedBox(width: 10),
                    Text(
                      "🚫 صلاحية التطبيق",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                Divider(height: 30, thickness: 1),

                // Device ID Section
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "معرف الجهاز:",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 5),
                            SelectableText(
                              _deviceId,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.blue),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _deviceId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم نسخ المعرف')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      "تواصل عبر واتساب للتجديد",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      launchUrl(Uri.parse(whatsappUrl));
                    },
                  ),
                ),
                SizedBox(height: 10),
                OutlinedButton(
                  child: Text(
                    "إغلاق التطبيق",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    SystemNavigator.pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel(); // ✅ أضفنا إلغاء التايمر هنا
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
            child: Image.asset(
              'assets/splash.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _animation,
              child: Image.asset(
                'assets/splash.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}






































