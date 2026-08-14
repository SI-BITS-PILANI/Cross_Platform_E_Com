import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bezier_container.dart';
import '../widgets/form_text_field.dart';
import '../widgets/primary_button.dart';
import '../navigation/smooth_page_route.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFieldKey = GlobalKey<FormTextFieldState>();
  final _passwordFieldKey = GlobalKey<FormTextFieldState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 8),
                    _buildForgotPassword(),
                    const SizedBox(height: 20),
                    _buildSignInButton(),
                    const SizedBox(height: 20),
                    _buildSignUpLink(),
                  ],
                ),
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
        text: 'S',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFe46b10),
        ),
        children: [
          TextSpan(
            text: 'hop',
            style: TextStyle(color: Colors.black, fontSize: 30),
          ),
          TextSpan(
            text: 'Ease',
            style: TextStyle(color: const Color(0xFFe46b10), fontSize: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return FormTextField(
      key: _usernameFieldKey,
      controller: _usernameController,
      label: 'Username',
      hint: 'Enter your username',
      prefixIcon: Icons.person_outline_rounded,
      keyboardType: TextInputType.name,
      validator: _validateUsername,
      onChanged: (_) => ref.read(authProvider.notifier).clearError(),
    );
  }

  Widget _buildPasswordField() {
    return FormTextField(
      key: _passwordFieldKey,
      controller: _passwordController,
      label: 'Password',
      hint: 'Enter your password',
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: true,
      showVisibilityToggle: true,
      validator: _validatePassword,
    );
  }

  Widget _buildForgotPassword() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading
            ? null
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password reset is not yet available. Please contact support.'),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
        child: Text(
          'Forgot Password ?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return PrimaryButton(
      label: _isLoading ? 'Signing In...' : 'Sign In',
      onPressed: _handleLogin,
      isLoading: _isLoading,
      enabled: !_isLoading,
      gradient: const LinearGradient(
        colors: [Color(0xFFfbb448), Color(0xFFf7892b)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          "Don't have an account ?",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _isLoading
              ? null
              : () {
                  Navigator.of(context).push(
                    SmoothPageRoute.push(context, const RegisterScreen()),
                  );
                },
          child: Text(
            'Sign Up',
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
}
