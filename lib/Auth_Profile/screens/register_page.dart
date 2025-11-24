import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  String? _kelamin; // 'L' atau 'P'
  DateTime? _tanggalLahir;
  bool _isLoading = false;

  final String baseUrl = "http://127.0.0.1:8000";

  // Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _tanggalLahir = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFFECFCCB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Register",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        children: [
                          TextSpan(text: "Join "),
                          TextSpan(
                            text: "MOVE BUDDY",
                            style: TextStyle(
                              color: Color(0xFF84CC16),
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          TextSpan(text: " today!"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Nama
                    _buildTextField(_namaController, "Nama Lengkap"),
                    const SizedBox(height: 16),

                    // Email
                    _buildTextField(_emailController, "Email", TextInputType.emailAddress),
                    const SizedBox(height: 16),

                    // Kelamin & Tanggal Lahir (Row)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _kelamin,
                            decoration: _inputDecoration("Kelamin"),
                            items: const [
                              DropdownMenuItem(value: "L", child: Text("Laki-laki")),
                              DropdownMenuItem(value: "P", child: Text("Perempuan")),
                            ],
                            onChanged: (val) => setState(() => _kelamin = val),
                            validator: (val) => val == null ? "Wajib diisi" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: _inputDecoration("Tanggal Lahir"),
                              child: Text(
                                _tanggalLahir == null
                                    ? "Pilih"
                                    : "${_tanggalLahir!.day}-${_tanggalLahir!.month}-${_tanggalLahir!.year}",
                                style: TextStyle(
                                  color: _tanggalLahir == null ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nomor Handphone
                    _buildTextField(_phoneController, "Nomor Handphone", TextInputType.phone),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _inputDecoration("Password"),
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Wajib diisi";
                        if (val.length < 8) return "Min 8 karakter";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Konfirmasi Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: _inputDecoration("Konfirmasi Password"),
                      validator: (val) {
                        if (val != _passwordController.text) return "Password tidak sama";
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF84CC16),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate() && _tanggalLahir != null) {
                                  setState(() => _isLoading = true);
                                  
                                  try {
                                    final response = await request.postJson(
                                      "$baseUrl/register/",
                                      jsonEncode({
                                        'nama': _namaController.text,
                                        'email': _emailController.text,
                                        'kelamin': _kelamin,
                                        // Format tanggal: YYYY-MM-DD
                                        'tanggal_lahir': "${_tanggalLahir!.year}-${_tanggalLahir!.month.toString().padLeft(2,'0')}-${_tanggalLahir!.day.toString().padLeft(2,'0')}",
                                        'nomor_handphone': _phoneController.text,
                                        'password': _passwordController.text,
                                        'password2': _confirmPasswordController.text,
                                      }),
                                    );

                                    if (context.mounted) {
                                      if (response['success'] == true) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Registrasi Berhasil! Silakan Login.")),
                                        );
                                        Navigator.pop(context); // Kembali ke Login Page
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(response['message'] ?? "Registrasi Gagal"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Error: $e")),
                                      );
                                    }
                                  } finally {
                                    setState(() => _isLoading = false);
                                  }
                                } else if (_tanggalLahir == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Tanggal lahir wajib diisi")),
                                  );
                                }
                              },
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Register",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Sudah punya akun? "),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Login di sini",
                            style: TextStyle(
                              color: Color(0xFF84CC16),
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  // Helper widget/method untuk TextField yang seragam
  Widget _buildTextField(TextEditingController controller, String label, [TextInputType? type]) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: _inputDecoration(label),
      validator: (val) => (val == null || val.isEmpty) ? "Wajib diisi" : null,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF84CC16), width: 2),
      ),
    );
  }
}