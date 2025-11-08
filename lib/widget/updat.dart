// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class UpdateChecker {
//   static Future<void> checkForUpdate(BuildContext context) async {
//     try {
//       await Firebase.initializeApp();
//       PackageInfo packageInfo = await PackageInfo.fromPlatform();
//       String currentVersion = packageInfo.version;
//
//       DocumentSnapshot snapshot = await FirebaseFirestore.instance
//           .collection('app_updates')
//           .doc('current_version')
//           .get();
//
//       if (snapshot.exists) {
//         String latestVersion = snapshot['latest_version'];
//         String minimumRequired = snapshot['minimum_required'];
//         String updateUrl = snapshot['update_url'];
//         bool forceUpdate = snapshot['force_update'] ?? false;
//         String releaseNotes = snapshot['release_notes'] ?? '';
//
//         if (_compareVersions(currentVersion, latestVersion) < 0) {
//           _showStyledUpdateDialog(
//             context,
//             forceUpdate: forceUpdate,
//             updateUrl: updateUrl,
//             releaseNotes: releaseNotes,
//             isCritical: _compareVersions(currentVersion, minimumRequired) < 0,
//           );
//         }
//       }
//     } catch (e) {
//       print('Error checking for update: $e');
//     }
//   }
//
//   static int _compareVersions(String v1, String v2) {
//     List<int> v1Parts = v1.split('.').map((e) => int.parse(e)).toList();
//     List<int> v2Parts = v2.split('.').map((e) => int.parse(e)).toList();
//
//     for (int i = 0; i < v1Parts.length; i++) {
//       if (v2Parts.length <= i) return 1;
//       if (v1Parts[i] > v2Parts[i]) return 1;
//       if (v1Parts[i] < v2Parts[i]) return -1;
//     }
//     return 0;
//   }
//
//   static void _showStyledUpdateDialog(
//       BuildContext context, {
//         required bool forceUpdate,
//         required String updateUrl,
//         required String releaseNotes,
//         required bool isCritical,
//       }) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async {
//             if (forceUpdate || isCritical) {
//               exit(0);
//             }
//             return false;
//           },
//           child: Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             elevation: 10,
//             child: Container(
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.system_update, color: Colors.blue, size: 40),
//                   SizedBox(height: 10),
//                   Text(
//                     "تحديث جديد متاح!",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue[800],
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     releaseNotes,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 16, color: Colors.black87),
//                   ),
//                   SizedBox(height: 15),
//                   if (isCritical || forceUpdate)
//                     Text(
//                       "هذا التحديث ضروري للاستمرار في استخدام التطبيق.",
//                       style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//                       textAlign: TextAlign.center,
//                     ),
//                   SizedBox(height: 20),
//                   ElevatedButton.icon(
//                     icon: Icon(Icons.download),
//                     label: Text("تحديث الآن"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue,
//                       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: () async {
//                       if (await canLaunchUrl(Uri.parse(updateUrl))) {
//                         await launchUrl(Uri.parse(updateUrl));
//                       }
//                       if (forceUpdate || isCritical) {
//                         exit(0);
//                       } else {
//                         Navigator.pop(context);
//                       }
//                     },
//                   ),
//                   SizedBox(height: 10),
//                   OutlinedButton.icon(
//                     icon: Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
//                     label: Text("تواصل عبر واتساب"),
//                     style: OutlinedButton.styleFrom(
//                       side: BorderSide(color: Colors.green),
//                       foregroundColor: Colors.green,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
//                     ),
//                     onPressed: () async {
//                       final whatsappUrl = Uri.parse(
//                         "https://wa.me/201153562128?text=مرحبًا، أحتاج إلى مساعدة بخصوص التحديث.",
//                       );
//                       if (await canLaunchUrl(whatsappUrl)) {
//                         await launchUrl(whatsappUrl);
//                       }
//                     },
//                   ),
//                   if (!isCritical && !forceUpdate) ...[
//                     SizedBox(height: 10),
//                     TextButton(
//                       child: Text("لاحقًا", style: TextStyle(color: Colors.grey[600])),
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                     ),
//                   ],
//                   SizedBox(height: 15),
//                   Text(
//                     "إذا واجهتك أي مشكلة، يُرجى التواصل مع الدعم الفني.",
//                     style: TextStyle(color: Colors.grey[700], fontSize: 14),
//                     textAlign: TextAlign.center,
//                   ),
//                   OutlinedButton.icon(
//                     icon: Icon(Icons.help_outline, size: 20),
//                     label: Text("تواصل مع الدعم"),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.amber[800],
//                       side: BorderSide(color: Colors.amber),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: EdgeInsets.symmetric(vertical: 12),
//                     ),
//                     onPressed: () async{
//                       final whatsappUrl = Uri.parse(
//                         "https://wa.me/201153562128?text=مرحبًا، أحتاج إلى مساعدة بخصوص التحديث.",
//                       );
//                       if (await canLaunchUrl(whatsappUrl)) {
//                       await launchUrl(whatsappUrl);
//                       }                    },
//                   ),
//
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
