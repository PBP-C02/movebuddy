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
  // Keep trailing slash and append paths without a leading slash.
  final String baseUrl = 'https://ari-darrell-movebuddy.pbp.cs.ui.ac.id/';

  // Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _kelamin; // 'L' atau 'P'
  DateTime? _tanggalLahir;
  bool _isLoading = false;

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
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFAEDB6A), Color(0xFF95C650)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                color: Colors.white,
                elevation: 18,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            children: [
                              TextSpan(text: "Create your "),
                              TextSpan(
                                text: "MOVE BUDDY",
                                style: TextStyle(
                                  color: Color(0xFFA2D94D),
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              TextSpan(text: " account"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),

                        _buildTextField(
                          _namaController,
                          "Nama",
                          hint: "Masukkan nama kamu",
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          _emailController,
                          "Email",
                          type: TextInputType.emailAddress,
                          hint: "Masukkan email kamu",
                        ),
                        const SizedBox(height: 14),
                        _buildDropdown(),
                        const SizedBox(height: 14),
                        _buildDateField(),
                        const SizedBox(height: 14),
                        _buildTextField(
                          _phoneController,
                          "Nomor Handphone",
                          type: TextInputType.phone,
                          hint: "Masukkan nomor handphone kamu",
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          controller: _passwordController,
                          label: "Password",
                          hint: "Pilih password",
                          validator: (val) {
                            if (val == null || val.isEmpty)
                              return "Wajib diisi";
                            if (val.length < 8) return "Min 8 karakter";
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: "Konfirmasi Password",
                          hint: "Konfirmasi password kamu",
                          validator: (val) {
                            if (val != _passwordController.text)
                              return "Password tidak sama";
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA2D94D),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate() &&
                                        _tanggalLahir != null) {
                                      setState(() => _isLoading = true);

                                      try {
                                        final response = await request.postJson(
                                          "${baseUrl}register/",
                                          jsonEncode({
                                            'nama': _namaController.text,
                                            'email': _emailController.text,
                                            'kelamin': _kelamin,
                                            'tanggal_lahir':
                                                "${_tanggalLahir!.year}-${_tanggalLahir!.month.toString().padLeft(2, '0')}-${_tanggalLahir!.day.toString().padLeft(2, '0')}",
                                            'nomor_handphone':
                                                _phoneController.text,
                                            'password':
                                                _passwordController.text,
                                            'password2':
                                                _confirmPasswordController.text,
                                          }),
                                        );

                                        if (context.mounted) {
                                          if (response['success'] == true) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Registrasi Berhasil! Silakan Login.",
                                                ),
                                              ),
                                            );
                                            Navigator.pop(context);
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  response['message'] ??
                                                      "Registrasi Gagal",
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $e"),
                                            ),
                                          );
                                        }
                                      } finally {
                                        setState(() => _isLoading = false);
                                      }
                                    } else if (_tanggalLahir == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Tanggal lahir wajib diisi",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Register",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Sudah punya akun? ",
                              style: TextStyle(color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Login di sini",
                                style: TextStyle(
                                  color: Color(0xFFA2D94D),
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
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? type,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          decoration: _inputDecoration(hint ?? label),
          validator: (val) =>
              (val == null || val.isEmpty) ? "Wajib diisi" : null,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: true,
          decoration: _inputDecoration(hint ?? label),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Jenis Kelamin",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _kelamin,
          decoration: _inputDecoration("Pilih Kelamin"),
          items: const [
            DropdownMenuItem(value: "L", child: Text("Laki-laki")),
            DropdownMenuItem(value: "P", child: Text("Perempuan")),
          ],
          onChanged: (val) => setState(() => _kelamin = val),
          validator: (val) => val == null ? "Wajib diisi" : null,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tanggal Lahir",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: _inputDecoration("mm/dd/yyyy"),
            child: Row(
              children: [
                Text(
                  _tanggalLahir == null
                      ? "mm/dd/yyyy"
                      : "${_tanggalLahir!.day.toString().padLeft(2, '0')}-${_tanggalLahir!.month.toString().padLeft(2, '0')}-${_tanggalLahir!.year}",
                  style: TextStyle(
                    color: _tanggalLahir == null ? Colors.grey : Colors.black87,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFA2D94D), width: 2),
      ),
    );
  }
}
