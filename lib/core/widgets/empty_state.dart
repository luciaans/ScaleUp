import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import 'mochi_companion.dart';
import 'primary_button.dart';

/// Empty State menggemaskan dengan ilustrasi Mochi si Kucing tidur melingkar.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = context.semanticColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MochiCompanion(
            pose: MochiPose.nap,
            size: 136,
            showFramedBadge: true,
            quotes: [
              'Zzz... belum ada catatan nih, yuk mulai!',
              'Meow~ ketuk tombol di bawah ya!',
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: semantic.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
              isFullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}
