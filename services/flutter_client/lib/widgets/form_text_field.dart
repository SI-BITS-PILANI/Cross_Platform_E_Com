import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FormTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool showVisibilityToggle;
  final List<String>? passwordRequirements;

  const FormTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.showVisibilityToggle = false,
    this.passwordRequirements,
  });

  @override
  State<FormTextField> createState() => FormTextFieldState();
}

class FormTextFieldState extends State<FormTextField>
    with SingleTickerProviderStateMixin {
  late bool _obscured;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasValue = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode = FocusNode();
    _hasValue = widget.controller.text.isNotEmpty;
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void triggerShake() {
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPassword = widget.obscureText || widget.showVisibilityToggle;
    final requirements = widget.passwordRequirements;
    final borderColor = _getBorderColor();
    final borderWidth = _isFocused ? 2.0 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: ShakeTransition(
            animation: _shakeAnimation,
            child: TextFormField(
              controller: widget.controller,
              obscureText: _obscured,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              onChanged: (value) {
                setState(() => _hasValue = value.isNotEmpty);
                widget.onChanged?.call(value);
              },
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: !_isFocused && !_hasValue ? widget.hint : null,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isFocused
                              ? AppTheme.primary.withValues(alpha: 0.12)
                              : AppTheme.textFieldFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: _isFocused ? AppTheme.primary : AppTheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                suffixIcon: widget.showVisibilityToggle
                    ? IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: Icon(
                            _obscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            key: ValueKey(_obscured),
                            size: 20,
                            color: _isFocused ? AppTheme.primary : AppTheme.onSurfaceVariant,
                          ),
                        ),
                        onPressed: () => setState(() => _obscured = !_obscured),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
          ),
        ),
        if (isPassword && requirements != null && requirements.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildPasswordRequirements(requirements),
        ],
      ],
    );
  }

  Color _getBorderColor() {
    if (_isFocused) return AppTheme.primary;
    final error = widget.validator?.call(widget.controller.text);
    if (error != null) return AppTheme.error;
    return AppTheme.textFieldBorder;
  }

  Widget _buildPasswordRequirements(List<String> requirements) {
    final password = widget.controller.text;
    final specialCharRegex = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]');
    final checks = <bool>[
      password.length >= 8,
      password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]')),
      password.contains(RegExp(r'[0-9]')),
      password.contains(specialCharRegex),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(checks.length, (index) {
        final met = checks[index];
        return AnimatedSize(
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 250 + (index * 50)),
                  curve: Curves.elasticOut,
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: met ? AppTheme.success : AppTheme.textFieldFill,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: met ? AppTheme.success : AppTheme.textFieldBorder,
                      width: 1,
                    ),
                  ),
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 200 + (index * 50)),
                    opacity: met ? 1 : 0,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: Duration(milliseconds: 200 + (index * 50)),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: met ? FontWeight.w500 : FontWeight.w400,
                      color: met ? AppTheme.success : AppTheme.onSurfaceVariant,
                    ),
                    child: Text(requirements[index]),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class ShakeTransition extends AnimatedWidget {
  final Widget child;
  const ShakeTransition({
    super.key,
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Transform.translate(
      offset: Offset(animation.value * (animation.value > 4 ? -1 : 1), 0),
      child: child,
    );
  }
}
