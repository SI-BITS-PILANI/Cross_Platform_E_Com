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
  });

  @override
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField>
    with SingleTickerProviderStateMixin {
  late bool _obscured;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = _isFocused
        ? AppTheme.primary
        : AppTheme.textFieldBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscured,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isFocused
                            ? AppTheme.primary.withOpacity(0.1)
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
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: _isFocused ? AppTheme.primary : AppTheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() => _obscured = !_obscured);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ),
        if (widget.validator != null) ...[
          const SizedBox(height: 6),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                _getErrorText(context) ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.error,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String? _getErrorText(BuildContext context) {
    final field = widget.controller.text;
    if (field.isEmpty) return null;
    final error = widget.validator?.call(field);
    return error;
  }
}
