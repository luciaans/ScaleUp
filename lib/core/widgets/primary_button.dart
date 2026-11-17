import 'package:material_ui/material_ui.dart';

import '../constants/app_spacing.dart';
import '../utils/reduce_motion.dart';

/// Tombol utama dengan animasi scale-down 0.96 saat ditekan + HapticFeedback.lightImpact.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _handleTapDown(TapDownDetails _) {
    if (!_isEnabled) return;
    setState(() => _isPressed = true);
  }

  void _handleTapEnd([dynamic _]) {
    if (_isPressed && mounted) {
      setState(() => _isPressed = false);
    }
  }

  void _handlePressed() {
    if (!_isEnabled) return;
    MotionUtils.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = MotionUtils.duration(context, AppSpacing.animFast);
    final scale = _isPressed && !MotionUtils.shouldReduceMotion(context)
        ? AppSpacing.pressedScale
        : 1.0;

    final fgColor = widget.foregroundColor ??
        (widget.isOutlined ? scheme.primary : scheme.onPrimary);

    final content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: AppSpacing.iconSm,
            height: AppSpacing.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: AppSpacing.borderThick,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: AppSpacing.iconSm),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    final Widget button = widget.isOutlined
        ? OutlinedButton(
            onPressed: _isEnabled ? _handlePressed : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: fgColor,
              side: BorderSide(color: widget.backgroundColor ?? scheme.primary),
            ),
            child: content,
          )
        : ElevatedButton(
            onPressed: _isEnabled ? _handlePressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor ?? scheme.primary,
              foregroundColor: fgColor,
            ),
            child: content,
          );

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapEnd,
      onTapCancel: _handleTapEnd,
      child: AnimatedScale(
        scale: scale,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          child: button,
        ),
      ),
    );
  }
}
