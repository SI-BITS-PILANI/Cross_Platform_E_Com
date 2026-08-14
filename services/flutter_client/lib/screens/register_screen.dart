import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bezier_container.dart';
import '../widgets/form_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

enum PasswordStrength { weak, medium, strong, empty }

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameFieldKey = GlobalKey<FormTextFieldState>();
  final _emailFieldKey = GlobalKey<FormTextFieldState>();
  final _passwordFieldKey = GlobalKey<FormTextFieldState>();
  final _confirmPasswordFieldKey = GlobalKey<FormTextFieldState>();
  bool _agreeToTerms = false;
  PasswordStrength _strength = PasswordStrength.empty;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _evaluateStrength(String password) {
    if (password.isEmpty) {
      setState(() => _strength = PasswordStrength.empty);
      return;
    }
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'))) {
      score++;
    }
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*]'))) score++;

    setState(() {
      if (score <= 1) {
        _strength = PasswordStrength.weak;
      } else if (score <= 3) {
        _strength = PasswordStrength.medium;
      } else {
        _strength = PasswordStrength.strong;
      }
    });
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 50) {
      return 'Username must be 50 characters or fewer';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    final messenger = ScaffoldMessenger.of(context);
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      _usernameFieldKey.currentState?.triggerShake();
      _emailFieldKey.currentState?.triggerShake();
      _passwordFieldKey.currentState?.triggerShake();
      _confirmPasswordFieldKey.currentState?.triggerShake();
      return;
    }
    if (!_agreeToTerms) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms & Conditions'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!success && mounted) {
      final error = ref.read(authProvider).error;
      if (error != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isLoading = ref.watch(authProvider).isLoading;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: height,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -height * 0.15,
              right: -MediaQuery.of(context).size.width * 0.4,
              child: const BezierContainer(),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: <Widget>[
                    SizedBox(height: height * 0.2),
                    _buildTitle(),
                    const SizedBox(height: 50),
                    _buildUsernameField(),
                    const SizedBox(height: 16),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 8),
                    _buildPasswordStrengthIndicator(),
                    const SizedBox(height: 12),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 20),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 20),
                    _buildSignUpButton(),
                    const SizedBox(height: 20),
                    _buildSignInLink(),
                  ],
                ),
              ),
            ),
            Positioned(top: 40, left: 0, child: _buildBackButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: _isLoading ? null : () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Icon(Icons.keyboard_arrow_left, color: Colors.black),
            ),
            Text(
              'Back',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'C',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFe46b10),
        ),
        children: [
          TextSpan(
            text: 'reate Account',
            style: TextStyle(color: Colors.black, fontSize: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return FormTextField(
      key: _usernameFieldKey,
      controller: _usernameController,
      label: 'Username',
      hint: 'johndoe',
      prefixIcon: Icons.person_outline_rounded,
      keyboardType: TextInputType.name,
      validator: _validateUsername,
      onChanged: (_) => ref.read(authProvider.notifier).clearError(),
    );
  }

  Widget _buildEmailField() {
    return FormTextField(
      key: _emailFieldKey,
      controller: _emailController,
      label: 'Email',
      hint: 'john@example.com',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return FormTextField(
      key: _passwordFieldKey,
      controller: _passwordController,
      label: 'Password',
      hint: 'Create a strong password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: true,
      showVisibilityToggle: true,
      validator: _validatePassword,
      onChanged: _evaluateStrength,
      passwordRequirements: const [
        'At least 8 characters',
        'Upper and lowercase letters',
        'Contains a number',
        'Contains special character',
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return FormTextField(
      key: _confirmPasswordFieldKey,
      controller: _confirmPasswordController,
      label: 'Confirm Password',
      hint: 'Re-enter your password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: true,
      showVisibilityToggle: true,
      validator: _validateConfirmPassword,
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  setState(() {
                    _agreeToTerms = !_agreeToTerms;
                  });
                },
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _agreeToTerms ? AppTheme.primary : Colors.black.withValues(alpha: 0.5),
                width: 2,
              ),
              color: _agreeToTerms ? AppTheme.primary : Colors.transparent,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _agreeToTerms ? 1 : 0,
              child: const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.8),
                fontSize: 13,
              ),
              children: [
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return PrimaryButton(
      label: _isLoading ? 'Creating Account...' : 'Sign Up',
      onPressed: _handleRegister,
      isLoading: _isLoading,
      enabled: !_isLoading,
      gradient: const LinearGradient(
        colors: [Color(0xFFfbb448), Color(0xFFf7892b)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account ?",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Sign In',
            style: TextStyle(
              color: const Color(0xFFf79c4f),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_strength == PasswordStrength.empty) {
      return const SizedBox.shrink();
    }

    final label = switch (_strength) {
      PasswordStrength.weak => 'Weak',
      PasswordStrength.medium => 'Medium',
      PasswordStrength.strong => 'Strong',
      PasswordStrength.empty => '',
    };

    final color = switch (_strength) {
      PasswordStrength.weak => AppTheme.error,
      PasswordStrength.medium => AppTheme.warning,
      PasswordStrength.strong => AppTheme.success,
      PasswordStrength.empty => Colors.transparent,
    };

    final barWidth = switch (_strength) {
      PasswordStrength.weak => 0.33,
      PasswordStrength.medium => 0.66,
      PasswordStrength.strong => 1.0,
      PasswordStrength.empty => 0.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Strength: $label',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(color: AppTheme.textFieldBorder),
            child: AnimatedFractionallySizedBox(
              widthFactor: barWidth,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.8), color],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
