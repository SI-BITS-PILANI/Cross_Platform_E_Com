import 'package:flutter/material.dart';

class AdaptiveAuthLayout extends StatelessWidget {
  final Widget brandPane;
  final Widget formPane;

  const AdaptiveAuthLayout({
    super.key,
    required this.brandPane,
    required this.formPane,
  });

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopLayout = isDesktop(context);

    if (isDesktopLayout) {
      return Row(
        children: [
          Expanded(
            flex: 5,
            child: brandPane,
          ),
          Expanded(
            flex: 5,
            child: _buildFormPane(context, formPane),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTablet(context) ? 480 : double.infinity,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet(context) ? 48 : 24,
              vertical: isTablet(context) ? 48 : 24,
            ),
            child: formPane,
          ),
        ),
      ),
    );
  }

  Widget _buildFormPane(BuildContext context, Widget form) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 64,
          right: 64,
          top: MediaQuery.of(context).size.height * 0.1,
          bottom: 48,
        ),
        child: form,
      ),
    );
  }
}
