
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wife_flutter/DatabaseHelper/DatabaseHelper.dart';
import 'package:wife_flutter/backups/backups.dart';
import 'package:file_picker/file_picker.dart';

class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final BackupManager backupManager = BackupManager(DatabaseHelper());
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    final data = await dbHelper.getUsers();
    setState(() {
      users = data;
      filteredUsers = data;

      isLoading = false;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        final name = user['name'].toString().toLowerCase();
        final address = user['address'].toString().toLowerCase();
        final phone = user['phone'].toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            address.contains(query.toLowerCase()) ||
            phone.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _showAddUserDialog(
      {Map<String, dynamic>? user, int? index}) async {
    final TextEditingController nameController =
        TextEditingController(text: user?['name']);
    final TextEditingController addressController =
        TextEditingController(text: user?['address']);
    final TextEditingController phoneController =
        TextEditingController(text: user?['phone']);

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user == null ? 'إضافة محطه جديد' : 'تعديل بيانات المحطه',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المحطه',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم التليفون',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.phone,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                      child:
                          Text('إلغاء', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('من فضلك اكتب الاسم')),
                          );
                          return;
                        }
                        if (addressController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('من فضلك اكتب العنوان')),
                          );
                          return;
                        }
                        if (phoneController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('من فضلك اكتب رقم الهاتف')),
                          );
                          return;
                        }

                        final userData = {
                          'name': nameController.text,
                          'address': addressController.text,
                          'phone': phoneController.text,
                        };

                        if (user == null) {
                          await dbHelper.insertUser(userData);
                        } else {
                          await dbHelper.updateUser(user['id'], userData);
                        }

                        _loadUsers();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                      child: Text('حفظ', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToSecondPage(int userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecondPage(userId: userId, userName: userName),
      ),
    );
  }

  Future<void> _deleteUser(int id) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا المحطه؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await dbHelper.deleteUser(id);
              _loadUsers();
              Navigator.of(context).pop();
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupDialog() async {
    final TextEditingController backupNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'إدارة النسخ الاحتياطية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: backupNameController,
                  decoration: InputDecoration(
                    labelText: 'اسم النسخة الاحتياطية',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.backup),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.save,
                  text: 'إنشاء نسخة احتياطية',
                  color: Colors.green,
                  onPressed: () async {
                    if (backupNameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('من فضلك اكتب اسم النسخة الاحتياطية')),
                      );
                      return;
                    }

                    await backupManager.backupData(backupNameController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('تم إنشاء النسخة الاحتياطية بنجاح')),
                    );
                    Navigator.of(context).pop();
                  },
                ),
                SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.restore,
                  text: 'استعادة نسخة احتياطية',
                  color: Colors.blue,
                  onPressed: () async {
                    final backups = await backupManager.getBackupsList();
                    if (backups.isNotEmpty) {
                      Navigator.of(context).pop();
                      await _showRestoreDialog(backups);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('لا توجد نسخ احتياطية متاحة')),
                      );
                    }
                  },
                ),
                SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.insert_drive_file,
                  text: 'استعادة من ملف',
                  color: Colors.orange,
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null) {
                      await backupManager
                          .restoreFromExternalFile(result.files.single.path!);
                      _loadUsers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم استعادة البيانات بنجاح')),
                      );
                    }
                    Navigator.of(context).pop();
                  },
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      Text('إغلاق', style: TextStyle(color: Colors.blue[800])),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String text,
      required Color color,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
      onPressed: onPressed,
    );
  }

  Future<void> _showRestoreDialog(List<String> backups) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اختر نسخة للاستعادة أو الحذف',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 300,
                  width: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: backups.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: Icon(Icons.backup, color: Colors.blue),
                          title: Text(backups[index]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.restore, color: Colors.green),
                                onPressed: () async {
                                  await backupManager.restoreFromBackup(backups[index]);
                                  _loadUsers();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('تم استعادة النسخة بنجاح')),
                                  );
                                  Navigator.of(context).pop();
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await _confirmAndDeleteBackup(backups[index]);
                                  setState(() {}); // لتحديث الواجهة
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('تم حذف النسخة بنجاح')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('إغلاق', style: TextStyle(color: Colors.blue[800])),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _confirmAndDeleteBackup(String backupName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد أنك تريد حذف النسخة "$backupName"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('لا'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('نعم'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteBackup(backupName);
      setState(() {}); // لتحديث الواجهة بعد الحذف
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف النسخة بنجاح')),
      );
    }
  }
  Future<void> _deleteBackup(String backupName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups/$backupName');
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في حذف النسخة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المحطات', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            onPressed: _showBackupDialog,
            icon: Icon(Icons.backup, color: Colors.white),
            tooltip: 'النسخ الاحتياطي',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue[800],
        elevation: 5,
        tooltip: 'إضافة محطه جديد',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
              ))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: searchController,
                        onSubmitted:_filterUsers ,
                        decoration: InputDecoration(
                          labelText: 'بحث عن المحطة',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),

                    if (filteredUsers.isEmpty)

                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 80, color: Colors.grey[400]),
                              SizedBox(height: 20),
                              Text(                                searchController.text.isEmpty

                                  ? 'لا يوجد محطات مسجلة'
                                  : 'لا توجد نتائج بحث',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => _showAddUserDialog(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 25, vertical: 12),
                                ),
                                child: Text('إضافة محطه جديد',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return Card(
                              elevation: 3,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(Icons.person,
                                      color: Colors.blue[800]),
                                ),
                                title: Text(
                                  user['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['address'] ?? '',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 4),
                                    // مسافة بسيطة بين العنوان والرقم
                                    Text(
                                      user['phone'] ?? '',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                onTap: () => _navigateToSecondPage(
                                    user['id'], user['name']),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showAddUserDialog(
                                          user: user, index: index),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteUser(user['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
































class SecondPage extends StatefulWidget {
  final int userId;
  final String userName;

  SecondPage({required this.userId, required this.userName});

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> devices = [];
  List<Map<String, dynamic>> filteredDevices = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => isLoading = true);
    final data = await dbHelper.getDevices(widget.userId);
    setState(() {
      devices = data;
      filteredDevices = List.from(devices);
      isLoading = false;
    });
  }

  void _filterDevices(String query) {
    setState(() {
      filteredDevices = devices
          .where((device) =>
              device['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _showAddDeviceDialog(
      {Map<String, dynamic>? device, int? index}) async {
    final TextEditingController nameController =
        TextEditingController(text: device?['name']);
    final TextEditingController ipController =
        TextEditingController(text: device?['ip']);
    final TextEditingController ssidController =
        TextEditingController(text: device?['ssid']);

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  device == null ? 'إضافة جهاز جديد' : 'تعديل بيانات الجهاز',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الجهاز',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.devices),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: ipController,
                  decoration: InputDecoration(
                    labelText: 'عنوان IP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 15),
                TextField(
                  controller: ssidController,
                  decoration: InputDecoration(
                    labelText: 'SSID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wifi),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                      child:
                          Text('إلغاء', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('من فضلك اكتب اسم الجهاز')),
                          );
                          return;
                        }
                        if (ipController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('من فضلك اكتب عنوان الـ IP')),
                          );
                          return;
                        }
                        if (ssidController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('من فضلك اكتب اسم الشبكة (SSID)')),
                          );
                          return;
                        }

                        final deviceData = {
                          'user_id': widget.userId,
                          'name': nameController.text,
                          'ip': ipController.text,
                          'ssid': ssidController.text,
                        };

                        if (device == null) {
                          await dbHelper.insertDevice(deviceData);
                        } else {
                          await dbHelper.updateDevice(device['id'], deviceData);
                        }

                        _loadDevices();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                      child: Text('حفظ', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAllIPs2() async {
    for (var device in devices) {
      final ip = device['ip'];
      if (ip != null && ip.isNotEmpty) {
        await launch('http://$ip');
      }
    }
  }

  Future<void> _openAllIPs() async {
    // 1. استخراج جميع الـ IPs مع تجاهل القيم الفارغة والمكررة
    final uniqueIPs = devices
        .map((device) =>
            device['ip']?.toString().trim()) // تحويل إلى نص وإزالة المسافات
        .where((ip) => ip != null && ip!.isNotEmpty) // تجاهل القيم الفارغة
        .toSet(); // إزالة التكرارات باستخدام Set

    // 2. طباعة الـ IPs الفريدة للتأكد (لأغراض debugging)
    print('Unique IPs to open: ${uniqueIPs.join(', ')}');

    // 3. فتح جميع الروابط بدون انتظار
    await Future.wait([
      for (var ip in uniqueIPs)
        launchUrl(Uri.parse('http://$ip')) // استخدام Uri.parse لأمان أفضل
    ]);
  }

  Future<void> _deleteDevice(int id) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا الجهاز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await dbHelper.deleteDevice(id);
              _loadDevices();
              Navigator.of(context).pop();
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('أجهزة ${widget.userName}',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue[800],
        elevation: 5,
        tooltip: 'إضافة جهاز جديد',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
              ))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: searchController,
                        onSubmitted: _filterDevices,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن جهاز بالاسم...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),

                    if (filteredDevices.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.devices_other,
                                  size: 80, color: Colors.grey[400]),
                              SizedBox(height: 20),
                              Text(
                                searchController.text.isEmpty
                                    ? 'لا يوجد أجهزة مسجلة'
                                    : 'لا توجد نتائج بحث',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 10),
                              if (searchController.text.isEmpty)
                                ElevatedButton(
                                  onPressed: () => _showAddDeviceDialog(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[800],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 25, vertical: 12),
                                  ),
                                  child: Text('إضافة جهاز جديد',
                                      style: TextStyle(color: Colors.white)),
                                )
                              else
                                ElevatedButton(
                                  onPressed: () {
                                    searchController.clear();
                                    _filterDevices('');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[600],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 25, vertical: 12),
                                  ),
                                  child: Text('مسح البحث',
                                      style: TextStyle(color: Colors.white)),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredDevices.length,
                          itemBuilder: (context, index) {
                            final device = filteredDevices[index];
                            return Card(
                              elevation: 3,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () async {
                                  await launch("http://${device['ip']}");
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.devices,
                                              color: Colors.blue, size: 30),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              device['name'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Colors.blue),
                                                onPressed: () =>
                                                    _showAddDeviceDialog(
                                                        device: device,
                                                        index: index),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _deleteDevice(device['id']),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Divider(),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Icons.numbers,
                                              color: Colors.grey[600],
                                              size: 20),
                                          SizedBox(width: 10),
                                          Text(
                                            'IP: ${device['ip']}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.wifi,
                                              color: Colors.grey[600],
                                              size: 20),
                                          SizedBox(width: 10),
                                          Text(
                                            'SSID: ${device['ssid']}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: ElevatedButton.icon(
                                          icon: Icon(Icons.open_in_browser,
                                              size: 18),
                                          label: Text('فتح الجهاز'),
                                          onPressed: () async {
                                            await launch(
                                                "http://${device['ip']}");
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[600],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (filteredDevices.isNotEmpty &&
                        searchController.text.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40.0),
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.all_inclusive,
                            color: Colors.red,
                          ),
                          label: Text(
                            'فتح جميع الأجهزة',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                                elevation: 10,
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.blue[50]!, Colors.white],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'افتح جميع المحطات',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        'اختر الطريقة التي تفضلها لفتح جميع الأجهزة',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 25),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildOptionButton(
                                            icon: ChromeIcon(),
                                            label: 'كروم العادي',
                                            onTap: () {
                                              Navigator.pop(context);
                                              _openAllIPs2();
                                            },
                                            color: Colors.blue,
                                          ),
                                          _buildOptionButton(
                                            icon: CachedNetworkImage(
                                              height: 50,
                                              width: 50,
                                              imageUrl:
                                                  'https://cdn4.iconfinder.com/data/icons/logos-brands-7/512/google_logo-google_icongoogle-512.png',
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                FontAwesomeIcons.google,
                                                color: Colors.deepPurple,size: 50,
                                              ),
                                            ),
                                            label: 'جوجل أساس',
                                            onTap: () {
                                              Navigator.pop(context);
                                              _openAllIPs();
                                            },
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 20),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'إلغاء',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.red[400],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 25, vertical: 12),
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

// دالة مساعدة لبناء أزرار الخيارات
Widget _buildOptionButton({
  required Widget icon,
  required String label,
  required VoidCallback onTap,
  required Color color,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: icon,
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class ChromeIcon extends StatelessWidget {
  const ChromeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(50, 50),
      painter: ChromeIconPainter(),
    );
  }
}

class ChromeIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // الأحمر
    paint.color = Colors.red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * 3.14 / 180,
      120 * 3.14 / 180,
      true,
      paint,
    );

    // الأخضر
    paint.color = Colors.green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      30 * 3.14 / 180,
      120 * 3.14 / 180,
      true,
      paint,
    );

    // الأصفر
    paint.color = Colors.yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      150 * 3.14 / 180,
      120 * 3.14 / 180,
      true,
      paint,
    );

    // دائرة بيضاء داخلية
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.5, paint);

    // دائرة زرقاء داخلية
    paint.color = Colors.blue;
    canvas.drawCircle(center, radius * 0.35, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
