import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../routing/app_router.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0; // 0 = Login, 1 = Sign Up
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Login controllers
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginPassVisible = false;
  bool _rememberMe = false;
  final _loginFormKey = GlobalKey<FormState>();

  // Sign Up controllers
  final _signUpNameCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPassCtrl = TextEditingController();
  final _signUpConfirmCtrl = TextEditingController();
  bool _signUpPassVisible = false;
  bool _signUpConfirmVisible = false;
  final _signUpFormKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _signUpNameCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _signUpPassCtrl.dispose();
    _signUpConfirmCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_tabIndex == index) return;
    _animCtrl.reset();
    setState(() => _tabIndex = index);
    _animCtrl.forward();
  }

  Future<void> _handleSubmit() async {
    final formKey = _tabIndex == 0 ? _loginFormKey : _signUpFormKey;
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildLogo(),
              const SizedBox(height: 36),
              _buildTabBar(),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fadeAnim,
                child: _tabIndex == 0 ? _buildLoginForm() : _buildSignUpForm(),
              ),
              const SizedBox(height: 20),
              _buildGoogleBtn(),
              const SizedBox(height: 28),
              _buildDisclaimer(),
              const SizedBox(height: 16),
              _buildFooterLinks(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 42),
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'DERMA',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI Skin Monitoring',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tabButton('Login', 0),
          _tabButton('Sign Up', 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _loginEmailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _loginPassCtrl,
            label: 'Password',
            hint: 'Min 8 characters',
            icon: Icons.lock_outline_rounded,
            obscure: !_loginPassVisible,
            suffix: IconButton(
              icon: Icon(
                _loginPassVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _loginPassVisible = !_loginPassVisible),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v!),
                activeColor: AppColors.primary,
              ),
              Text(
                'Remember me',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showStub('Forgot password coming soon!'),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Login',
            onPressed: _handleSubmit,
            isLoading: _isLoading,
            icon: Icons.login_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _signUpNameCtrl,
            label: 'Full Name',
            hint: 'Ahmed Al-Rashid',
            icon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Full name is required';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _signUpEmailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _signUpPassCtrl,
            label: 'Password',
            hint: 'Min 8 characters',
            icon: Icons.lock_outline_rounded,
            obscure: !_signUpPassVisible,
            suffix: IconButton(
              icon: Icon(
                _signUpPassVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _signUpPassVisible = !_signUpPassVisible),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Minimum 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _signUpConfirmCtrl,
            label: 'Confirm Password',
            hint: 'Repeat your password',
            icon: Icons.lock_reset_rounded,
            obscure: !_signUpConfirmVisible,
            suffix: IconButton(
              icon: Icon(
                _signUpConfirmVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _signUpConfirmVisible = !_signUpConfirmVisible),
            ),
            validator: (v) {
              if (v != _signUpPassCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'By creating an account you agree to our Terms of Service and Privacy Policy.',
            style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Create Account',
            onPressed: _handleSubmit,
            isLoading: _isLoading,
            icon: Icons.person_add_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildGoogleBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showStub('Google sign-in coming soon!'),
        icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF97316),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This app does not replace medical diagnosis. Always consult a licensed dermatologist.',
              style: AppTextStyles.small.copyWith(
                color: const Color(0xFF92400E),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => _showStub('Privacy Policy'),
          child: Text(
            'Privacy Policy',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        Text('·', style: TextStyle(color: AppColors.textMuted)),
        TextButton(
          onPressed: () => _showStub('Terms of Service'),
          child: Text(
            'Terms of Service',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  void _showStub(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
