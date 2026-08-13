import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DemoCredentialsCard extends StatelessWidget {
  const DemoCredentialsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withAlpha(40), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Demo Credentials',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCredentialRow(context, 'alice', 'password123', 'customer'),
          _buildCredentialRow(context, 'admin', 'admin123', 'admin, customer'),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(
    BuildContext context,
    String username,
    String password,
    String roles,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 14, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '$username / $password',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            '($roles)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
