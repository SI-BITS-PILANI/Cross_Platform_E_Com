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
import '../widgets/demo_credentials_card.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFieldKey = GlobalKey<FormTextFieldState>();
  final _passwordFieldKey = GlobalKey<FormTextFieldState>();
  bool _rememberMe = false;
  bool _showDemoCredentials = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    final messenger = ScaffoldMessenger.of(context);
    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      _usernameFieldKey.currentState?.triggerShake();
      _passwordFieldKey.currentState?.triggerShake();
      return;
    }

    final success = await ref.read(authProvider.notifier).login(
          username: _usernameController.text.trim(),
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
                formPane: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!AdaptiveAuthLayout.isDesktop(context)) ...[
                        _buildMobileHeader(),
                        const SizedBox(height: 32),
                      ],
                      AuthCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (AdaptiveAuthLayout.isDesktop(context)) ...[
                              Center(
                                child: Text(
                                  'Welcome Back',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        color: AppTheme.onSurface,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Text(
                                  'Sign in to continue shopping',
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
                                hint: 'Enter your username',
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
                                key: _passwordFieldKey,
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: true,
                                showVisibilityToggle: true,
                                validator: _validatePassword,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _AnimatedFormField(
                              delay: 260,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(7),
                                          border: Border.all(
                                            color: _rememberMe
                                                ? AppTheme.primary
                                                : AppTheme.textFieldBorder,
                                            width: 2,
                                          ),
                                          color: _rememberMe
                                              ? AppTheme.primary
                                              : Colors.transparent,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _rememberMe = !_rememberMe;
                                            });
                                          },
                                          child: AnimatedOpacity(
                                            duration: const Duration(milliseconds: 150),
                                            opacity: _rememberMe ? 1 : 0,
                                            child: const Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Remember me',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                    'Password reset is not yet available. Please contact support.'),
                                                backgroundColor: AppTheme.error,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(12)),
                                              ),
                                            );
                                          },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            _AnimatedFormField(
                              delay: 340,
                              child: PrimaryButton(
                                label: isLoading ? 'Signing In...' : 'Sign In',
                                onPressed: _handleLogin,
                                isLoading: isLoading,
                                enabled: !isLoading,
                                icon: Icons.login_rounded,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_showDemoCredentials) ...[
                              _AnimatedFormField(
                                delay: 400,
                                child: const DemoCredentialsCard(),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _showDemoCredentials =
                                            !_showDemoCredentials;
                                      });
                                    },
                              child: Text(
                                _showDemoCredentials
                                    ? 'Hide Demo Credentials'
                                    : 'Show Demo Credentials',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                        child: Text(
                          'Don\'t have an account? Sign Up',
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
          'Your marketplace, reimagined.',
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
