import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/register_request_model.dart';
import '../viewmodels/register_viewmodel.dart';
import 'login_page.dart';

class RegisterView extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  DateTime? _selectedBirthDate;
  bool _isPasswordVisible = false;

  static const Color _primaryRed = Color(0xFFE53935);
  static const Color _darkRed = Color(0xFF9F1212);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF6B7280);

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _phoneNumberController.dispose();
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 17),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryRed,
              onPrimary: Colors.white,
              onSurface: _textDark,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedBirthDate = pickedDate;
      _birthDateController.text = _formatDateForDisplay(pickedDate);
    });
  }

  String _formatDateForDisplay(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year';
  }

  Future<void> _submitRegister() async {
    FocusScope.of(context).unfocus();

    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final RegisterRequestModel request = RegisterRequestModel(
      fullName: _fullNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      birthDate: _selectedBirthDate,
      phoneNumber: _phoneNumberController.text,
      nim: _nimController.text,
      password: _passwordController.text,
    );

    final RegisterViewModel viewModel = context.read<RegisterViewModel>();

    final bool isSuccess = await viewModel.register(request);

    if (!mounted) return;

    final String? errorMessage = viewModel.errorMessage;
    final String? successMessage = viewModel.successMessage;

    if (isSuccess) {
      _passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(successMessage ?? 'Registrasi berhasil. Silakan login.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginPage.routeName,
        (Route<dynamic> route) => false,
      );
    } else if (errorMessage != null && errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginPage.routeName,
      (Route<dynamic> route) => false,
    );
  }

  void _handleBackPressed() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final RegisterViewModel viewModel = context.watch<RegisterViewModel>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF5252),
              _primaryRed,
              _darkRed,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            _buildDecorativeBackground(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 28),
                    _buildRegisterCard(viewModel),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeBackground() {
    return Stack(
      children: [
        Positioned(
          top: 80,
          right: -80,
          child: Transform.rotate(
            angle: -0.7,
            child: Container(
              width: 220,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
        ),
        Positioned(
          top: 180,
          left: -70,
          child: Transform.rotate(
            angle: -0.7,
            child: Container(
              width: 220,
              height: 2,
              color: Colors.white.withOpacity(0.45),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -40,
          child: Transform.rotate(
            angle: -0.7,
            child: Container(
              width: 180,
              height: 2,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            InkWell(
              onTap: _handleBackPressed,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Sign up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sudah punya akun? ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: _goToLogin,
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Color(0xFFBBDEFB),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFBBDEFB),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterCard(RegisterViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Buat Akun Baru',
              style: TextStyle(
                color: _textDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lengkapi data diri kamu untuk mulai belajar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _fullNameController,
              label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap',
              icon: Icons.person_outline_rounded,
              validator: _requiredValidator,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              hint: 'Masukkan username',
              icon: Icons.alternate_email_rounded,
              validator: _requiredValidator,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'user@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _birthDateController,
              label: 'Tanggal Lahir',
              hint: 'dd/mm/yyyy',
              icon: Icons.cake_outlined,
              readOnly: true,
              enabled: !viewModel.isLoading,
              onTap: viewModel.isLoading ? null : _selectBirthDate,
              suffixIcon: IconButton(
                onPressed: viewModel.isLoading ? null : _selectBirthDate,
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: _textGrey,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _phoneNumberController,
              label: 'Nomor Telepon',
              hint: 'Masukkan nomor telepon',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: _requiredValidator,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _nimController,
              label: 'NIM',
              hint: 'Masukkan NIM jika ada',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.text,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Minimal 8 karakter',
              icon: Icons.lock_outline_rounded,
              obscureText: !_isPasswordVisible,
              validator: _passwordValidator,
              enabled: !viewModel.isLoading,
              suffixIcon: IconButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _textGrey,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: viewModel.isLoading ? null : _submitRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryRed,
                  disabledBackgroundColor: _primaryRed.withOpacity(0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: viewModel.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onTap: onTap,
      style: const TextStyle(
        color: _textDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: _textGrey,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        labelStyle: const TextStyle(
          color: _textGrey,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _primaryRed,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }

    final RegExp emailRegex = RegExp(
      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }

    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }

    return null;
  }
}
