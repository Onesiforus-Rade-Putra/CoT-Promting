import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_view_model.dart';
import 'dashboard_page.dart';
import 'reset_password_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  static const String routeName = '/login';

  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailOrUsernameController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  bool get _canSubmit {
    return _emailOrUsernameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    _emailOrUsernameController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _emailOrUsernameController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);

    _emailOrUsernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    final authViewModel = context.read<AuthViewModel>();

    final success = await authViewModel.login(
      emailOrUsername: _emailOrUsernameController.text,
      password: _passwordController.text,
    );

    _passwordController.clear();

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(
        context,
        DashboardPage.routeName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
          return Stack(
            children: [
              const _LoginBackground(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 430,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _LoginHeader(),
                          const SizedBox(height: 32),
                          _LoginCard(
                            formKey: _formKey,
                            emailOrUsernameController:
                                _emailOrUsernameController,
                            passwordController: _passwordController,
                            isPasswordVisible: _isPasswordVisible,
                            canSubmit: _canSubmit,
                            isLoading: authViewModel.isLoading,
                            errorMessage: authViewModel.errorMessage,
                            rememberMe: authViewModel.rememberMe,
                            onRememberMeChanged: (value) {
                              authViewModel.setRememberMe(value ?? false);
                            },
                            onTogglePasswordVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            onLoginPressed: _handleLogin,
                            onForgotPasswordPressed: () {
                              Navigator.pushNamed(
                                context,
                                ResetPasswordPage.routeName,
                              );
                            },
                            onSignUpPressed: () {
                              Navigator.pushNamed(
                                context,
                                RegisterView.routeName,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DiagonalDecorationPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF3B30),
              Color(0xFFB00020),
              Color(0xFF730014),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}

class _DiagonalDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint whiteShapePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final Path topShape = Path()
      ..moveTo(size.width * 0.65, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.26)
      ..lineTo(size.width * 0.42, size.height * 0.08)
      ..close();

    canvas.drawPath(topShape, whiteShapePaint);

    final Path bottomShape = Path()
      ..moveTo(0, size.height * 0.78)
      ..lineTo(size.width * 0.58, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(bottomShape, whiteShapePaint);

    final Paint linePaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.06, size.height * 0.18),
      Offset(size.width * 0.9, size.height * 0.05),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.86),
      Offset(size.width * 0.86, size.height * 0.72),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.72, size.height * 0.18),
      Offset(size.width, size.height * 0.32),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Color(0xFFD71920),
            size: 48,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Mahasiswa Sukses',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Belajar Sambil Berkompetisi!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailOrUsernameController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool canSubmit;
  final bool isLoading;
  final String? errorMessage;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onLoginPressed;
  final VoidCallback onForgotPasswordPressed;
  final VoidCallback onSignUpPressed;

  const _LoginCard({
    required this.formKey,
    required this.emailOrUsernameController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.canSubmit,
    required this.isLoading,
    required this.errorMessage,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onTogglePasswordVisibility,
    required this.onLoginPressed,
    required this.onForgotPasswordPressed,
    required this.onSignUpPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isButtonEnabled = canSubmit && !isLoading;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selamat Datang',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Login untuk melanjutkan petualangan mu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            if (errorMessage != null) ...[
              _ErrorBox(message: errorMessage!),
              const SizedBox(height: 16),
            ],
            _FieldLabel(label: 'Email atau Username'),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailOrUsernameController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
              decoration: _inputDecoration(
                hintText: 'Masukkan email atau username',
                prefixIcon: Icons.person_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email/username wajib diisi.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              textInputAction: TextInputAction.done,
              enabled: !isLoading,
              onFieldSubmitted: (_) {
                if (isButtonEnabled) {
                  onLoginPressed();
                }
              },
              decoration: _inputDecoration(
                hintText: 'Masukkan password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: isLoading ? null : onTogglePasswordVisibility,
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password wajib diisi.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: isLoading ? null : onRememberMeChanged,
                    activeColor: const Color(0xFFD71920),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember me',
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: isLoading ? null : onForgotPasswordPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Lupa password?',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isButtonEnabled ? onLoginPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD71920),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: const Color(0xFF9CA3AF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Belum punya akun? ',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: isLoading ? null : onSignUpPressed,
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF9CA3AF),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
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
          color: Color(0xFFD71920),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.4,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFCDD2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD71920),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
