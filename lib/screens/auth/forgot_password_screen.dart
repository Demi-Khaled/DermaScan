import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  int _step = 0; // 0: Email, 1: OTP, 2: New Password
  bool _isLoading = false;
  bool _passVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleStep0() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.forgotPassword(_emailCtrl.text.trim());
      setState(() => _step = 1);
      _showSnackBar('OTP sent to your email');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStep1() async {
    if (_otpCtrl.text.length < 6) {
      _showSnackBar('Please enter the 6-digit OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.verifyOTP(_emailCtrl.text.trim(), _otpCtrl.text.trim());
      setState(() => _step = 2);
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStep2() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.resetPassword(
        _emailCtrl.text.trim(),
        _otpCtrl.text.trim(),
        _newPassCtrl.text,
      );
      _showSnackBar('Password reset successful! Please login.');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.getAdaptiveTextPrimary(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 32),
              Text(
                _getStepTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStepSubtitle(),
                style: TextStyle(
                  color: AppColors.getAdaptiveTextMuted(context),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: _buildStepContent(),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: _getButtonLabel(),
                onPressed: _isLoading ? () {} : _onContinue,
                isLoading: _isLoading,
                icon: _isLoading ? null : Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  String _getStepTitle() {
    if (_step == 0) return 'Forgot Password?';
    if (_step == 1) return 'Verify OTP';
    return 'New Password';
  }

  String _getStepSubtitle() {
    if (_step == 0) return 'Enter your email to receive a password reset code.';
    if (_step == 1) return 'We sent a 6-digit code to ${_emailCtrl.text}';
    return 'Create a strong new password for your account.';
  }

  String _getButtonLabel() {
    if (_step == 0) return 'Send Code';
    if (_step == 1) return 'Verify Code';
    return 'Reset Password';
  }

  void _onContinue() {
    if (_step == 0) {
      _handleStep0();
    } else if (_step == 1) {
      _handleStep1();
    } else {
      _handleStep2();
    }
  }

  Widget _buildStepContent() {
    if (_step == 0) {
      return TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email Address',
          hintText: 'you@example.com',
          prefixIcon: Icon(Icons.email_outlined),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Email is required';
          if (!v.contains('@')) return 'Enter a valid email';
          return null;
        },
      );
    }

    if (_step == 1) {
      return Column(
        children: [
          TextFormField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              labelText: '6-Digit Code',
              hintText: '000000',
              counterText: '',
              prefixIcon: Icon(Icons.security_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : _handleStep0,
            child: const Text('Resend Code'),
          ),
        ],
      );
    }

    return Column(
      children: [
        TextFormField(
          controller: _newPassCtrl,
          obscureText: !_passVisible,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_passVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _passVisible = !_passVisible),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Minimum 8 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPassCtrl,
          obscureText: !_passVisible,
          decoration: const InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: Icon(Icons.lock_reset_rounded),
          ),
          validator: (v) {
            if (v != _newPassCtrl.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }
}
