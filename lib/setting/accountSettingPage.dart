import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AccountSettingPage extends StatefulWidget {
  const AccountSettingPage({super.key});

  @override
  _AccountSettingPageState createState() => _AccountSettingPageState();
}

class _AccountSettingPageState extends State<AccountSettingPage> {
  // Trạng thái dữ liệu
  Map<String, dynamic> userData = {};
  Map<String, bool> isEditing = {
    'name': false,
    'phone': false,
    'gender': false,
    'height': false,
    'weight': false,
    'birthdate': false,
    'address': false, // Add address to the list of editable fields
  };

  // Các controller cho TextField
  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'phone': TextEditingController(),
    'gender': TextEditingController(),
    'height': TextEditingController(),
    'weight': TextEditingController(),
    'birthdate': TextEditingController(),
    'address': TextEditingController(), // Add controller for address
  };

  bool _isLoading = true;

  // Các biến để lưu trạng thái tỉnh, huyện, xã
  String? selectedProvince;
  String? selectedDistrict;
  String? selectedWard;

  // Dữ liệu tỉnh, huyện, xã
  List<dynamic> provinces = [];

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Gọi phương thức tải dữ liệu người dùng
    _loadProvinceData(); // Tải dữ liệu tỉnh, huyện, xã từ file JSON
  }

  // Hàm tải dữ liệu người dùng từ Firebase hoặc asset
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseFirestore.instance.collection('User').doc(user.uid);
        final docSnapshot = await ref.get(); // Lấy dữ liệu từ Firestore

        if (docSnapshot.exists) {
          final userDataFromFirestore =
              docSnapshot.data() as Map<String, dynamic>;

          // Debug in ra dữ liệu
          print('Dữ liệu người dùng từ Firestore: $userDataFromFirestore');

          setState(() {
            userData = userDataFromFirestore;
            _isLoading = false;
            controllers.forEach((key, controller) {
              controller.text = userData[key]?.toString() ??
                  ''; // Cập nhật controller từ Firestore
            });
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy dữ liệu người dùng')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
    }
  }

  // Hàm tải dữ liệu tỉnh, huyện, xã từ file JSON
  Future<void> _loadProvinceData() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/full_json_generated_data_vn_units.json');
      final List<dynamic> jsonData = json.decode(jsonString);

      setState(() {
        provinces = jsonData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu tỉnh, huyện, xã: $e')));
    }
  }

  // Hàm lưu thông tin địa chỉ lên Firebase
  Future<void> _saveAddressToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseFirestore.instance.collection('User').doc(user.uid);

        // Kết hợp thông tin địa chỉ
        final address = {
          'province': selectedProvince,
          'district': selectedDistrict,
          'ward': selectedWard,
          'address': controllers['address']!.text,
        };

        // Cập nhật Firestore với dữ liệu địa chỉ
        await ref.update({
          'address': address, // Lưu địa chỉ vào Firestore
        });

        setState(() {
          userData['address'] = address; // Cập nhật dữ liệu người dùng địa chỉ
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật địa chỉ thành công!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi lưu địa chỉ: $e')));
    }
  }

  // Hàm xử lý khi chọn tỉnh
  void _onProvinceSelected(String? province) {
    setState(() {
      selectedProvince = province;
      selectedDistrict = null;
      selectedWard = null; // Reset lại huyện và xã khi thay đổi tỉnh
    });

    // Save the address when province is selected
    _saveAddressToFirebase();
  }

  // Hàm xử lý khi chọn huyện
  void _onDistrictSelected(String? district) {
    setState(() {
      selectedDistrict = district;
      selectedWard = null; // Reset lại xã khi thay đổi huyện
    });

    // Save the address when district is selected
    _saveAddressToFirebase();
  }

  // Hàm xử lý khi chọn xã
  void _onWardSelected(String? ward) {
    setState(() {
      selectedWard = ward;
    });

    // Save the address when ward is selected
    _saveAddressToFirebase();
  }

  // Widget hiển thị trường dữ liệu có thể chỉnh sửa
  Widget _buildEditableField(String label, String key) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: isEditing[key]!
              ? TextField(
                  controller: controllers[key],
                  decoration: InputDecoration(labelText: label),
                )
              : Text(
                  '$label: ${userData[key] ?? 'Chưa có dữ liệu'}',
                  style: const TextStyle(fontSize: 18),
                ),
        ),
        IconButton(
          icon: Icon(isEditing[key]! ? Icons.save : Icons.edit),
          onPressed: () {
            if (isEditing[key]!) {
              if (key == 'address') {
                _saveAddressToFirebase();
              } else {
                _saveFieldToFirebase(key);
              }
            } else {
              setState(() {
                isEditing[key] = true;
              });
            }
          },
        ),
      ],
    );
  }

  // Hàm lưu thông tin vào Firebase
  Future<void> _saveFieldToFirebase(String key) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseFirestore.instance.collection('User').doc(user.uid);

        await ref.update({
          key: controllers[key]!.text, // Lưu thông tin từ controller
        });

        setState(() {
          userData[key] =
              controllers[key]!.text; // Cập nhật dữ liệu trong userData
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Cập nhật $key thành công!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi lưu $key: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildEditableField('Tên', 'name'),
            const Divider(),
            _buildEditableField('Số điện thoại', 'phone'),
            const Divider(),
            _buildEditableField('Giới tính', 'gender'),
            const Divider(),
            _buildEditableField('Chiều cao (cm)', 'height'),
            const Divider(),
            _buildEditableField('Cân nặng (kg)', 'weight'),
            const Divider(),
            _buildEditableField('Ngày sinh', 'birthdate'),
            const Divider(),

            // Dropdown cho tỉnh
            DropdownButton<String>(
              value: selectedProvince,
              hint: Text('Chọn tỉnh'),
              onChanged: _onProvinceSelected,
              items: provinces.isEmpty
                  ? [
                      DropdownMenuItem<String>(
                          child: Text('Không có dữ liệu tỉnh'))
                    ]
                  : provinces.map<DropdownMenuItem<String>>((province) {
                      return DropdownMenuItem<String>(
                        value: province['Name'],
                        child: Text(province['Name'] ?? 'Không có tên'),
                      );
                    }).toList(),
            ),
            const Divider(),

            // Dropdown cho huyện
            if (selectedProvince != null) ...[
              DropdownButton<String>(
                value: selectedDistrict,
                hint: Text('Chọn huyện'),
                onChanged: _onDistrictSelected,
                items: (provinces.firstWhere((province) =>
                            province['Name'] == selectedProvince)['District']
                        as List)
                    .map<DropdownMenuItem<String>>((district) {
                  return DropdownMenuItem<String>(
                    value: district['Name'],
                    child: Text(district['Name'] ?? 'Không có tên'),
                  );
                }).toList(),
              ),
            ],
            const Divider(),

            // Dropdown cho xã
            if (selectedDistrict != null) ...[
              DropdownButton<String>(
                value: selectedWard,
                hint: Text('Chọn xã'),
                onChanged: _onWardSelected,
                items: (provinces.firstWhere((province) =>
                            province['Name'] == selectedProvince)['District']
                        as List)
                    .firstWhere((district) =>
                        district['Name'] == selectedDistrict)['Ward']
                    .map<DropdownMenuItem<String>>((ward) {
                  return DropdownMenuItem<String>(
                    value: ward['Name'],
                    child: Text(ward['Name'] ?? 'Không có tên'),
                  );
                }).toList(),
              ),
            ],
            const Divider(),

            // Address field
            _buildEditableField('Địa chỉ', 'address'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}
