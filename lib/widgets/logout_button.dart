import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class LogoutButton extends StatelessWidget {
  final bool showConfirmation;
  final VoidCallback? onLogoutComplete;
  final Color? backgroundColor;
  final Color? textColor;
  final String? customText;
  final IconData? customIcon;

  const LogoutButton({
    super.key,
    this.showConfirmation = true,
    this.onLogoutComplete,
    this.backgroundColor,
    this.textColor,
    this.customText,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: backgroundColor != null
              ? [backgroundColor!, backgroundColor!.withOpacity(0.8)]
              : [Colors.red[600]!, Colors.red[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? Colors.red[600]!).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleLogout(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  customIcon ?? Icons.logout_rounded,
                  color: textColor ?? Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  customText ?? 'Sign Out',
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    if (showConfirmation) {
      // Show confirmation dialog
      final shouldSignOut = await AuthService.showLogoutConfirmation(context);
      if (shouldSignOut) {
        await AuthService.signOut(context);
        onLogoutComplete?.call();
      }
    } else {
      // Direct logout without confirmation
      await AuthService.signOut(context);
      onLogoutComplete?.call();
    }
  }
}

class LogoutIconButton extends StatelessWidget {
  final bool showConfirmation;
  final VoidCallback? onLogoutComplete;
  final Color? iconColor;
  final double? iconSize;
  final String? tooltip;

  const LogoutIconButton({
    super.key,
    this.showConfirmation = true,
    this.onLogoutComplete,
    this.iconColor,
    this.iconSize,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _handleLogout(context),
      icon: Icon(
        Icons.logout_rounded,
        color: iconColor ?? Colors.red[600],
        size: iconSize ?? 24,
      ),
      tooltip: tooltip ?? 'Sign Out',
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: iconColor ?? Colors.red[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Haptic feedback
    HapticFeedback.lightImpact();

    if (showConfirmation) {
      // Show confirmation dialog
      final shouldSignOut = await AuthService.showLogoutConfirmation(context);
      if (shouldSignOut) {
        await AuthService.signOut(context);
        onLogoutComplete?.call();
      }
    } else {
      // Direct logout without confirmation
      await AuthService.signOut(context);
      onLogoutComplete?.call();
    }
  }
}
