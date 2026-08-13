import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/adaptive_auth_layout.dart';
import '../widgets/brand_header.dart';
import '../widgets/gradient_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/form_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

enum PasswordStrength { weak, medium, strong, empty }

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
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
    final isLoading = ref.watch(authProvider).isLoading;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: GradientBackground(
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: AdaptiveAuthLayout(
                brandPane: AdaptiveAuthLayout.isDesktop(context)
                    ? const BrandHeader()
                    : const SizedBox.shrink(),
                formPane: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (!AdaptiveAuthLayout.isDesktop(context)) ...[
                        _buildMobileHeader(),
                        const SizedBox(height: 32),
                      ],
                      AuthCard(
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                            if (AdaptiveAuthLayout.isDesktop(context)) ...[
                              Center(
                                child: Text(
                                  'Create Account',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(color: AppTheme.onSurface),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Text(
                                  'Start your shopping journey',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                            _AnimatedFormField(
                              delay: 100,
                              child: FormTextField(
                                key: _usernameFieldKey,
                                controller: _usernameController,
                                label: 'Username',
                                hint: 'johndoe',
                                prefixIcon: Icons.person_outline_rounded,
                                keyboardType: TextInputType.name,
                                validator: _validateUsername,
                                onChanged: (_) =>
                                    ref.read(authProvider.notifier).clearError(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _AnimatedFormField(
                              delay: 180,
                              child: FormTextField(
                                key: _emailFieldKey,
                                controller: _emailController,
                                label: 'Email',
                                hint: 'john@example.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _AnimatedFormField(
                              delay: 260,
                              child: FormTextField(
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
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPasswordStrengthIndicator(),
                            const SizedBox(height: 12),
                            _AnimatedFormField(
                              delay: 340,
                              child: FormTextField(
                                key: _confirmPasswordFieldKey,
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                hint: 'Re-enter your password',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: true,
                                showVisibilityToggle: true,
                                validator: _validateConfirmPassword,
                                onChanged: (_) =>
                                    _formKey.currentState?.validate(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _AnimatedFormField(
                              delay: 400,
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                        color: _agreeToTerms
                                            ? AppTheme.primary
                                            : AppTheme.textFieldBorder,
                                        width: 2,
                                      ),
                                      color: _agreeToTerms
                                          ? AppTheme.primary
                                          : Colors.transparent,
                                    ),
                                    child: GestureDetector(
                                      onTap: isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _agreeToTerms = !_agreeToTerms;
                                              });
                                            },
                                      child: AnimatedOpacity(
                                        duration: const Duration(milliseconds: 150),
                                        opacity: _agreeToTerms ? 1 : 0,
                                        child: const Icon(
                                          Icons.check_rounded,
                                          size: 16,
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
                                        style:
                                            Theme.of(context).textTheme.bodyMedium,
                                        children: [
                                          TextSpan(
                                            text: 'Terms & Conditions',
                                            style: TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            _AnimatedFormField(
                              delay: 460,
                              child: PrimaryButton(
                                label: isLoading ? 'Creating Account...' : 'Sign Up',
                                onPressed: _handleRegister,
                                isLoading: isLoading,
                                enabled: !isLoading,
                                icon: Icons.person_add_rounded,
                              ),
                            ),
                          ],
                         ),
                       ),
                     ),
                       const SizedBox(height: 20),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          'Already have an account? Sign In',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                     ],
                   ),
                 ),
               ),
             ),
           ),
         ),
       ),
     );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ShopEase',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
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

class _AnimatedFormField extends StatelessWidget {
  final int delay;
  final Widget child;

  const _AnimatedFormField({
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
