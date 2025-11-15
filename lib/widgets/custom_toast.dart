import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

void showSuccessToast(BuildContext context, String message) {
  _showSmartToast(
    context,
    message,
    icon: Icons.check_circle_rounded,
    color: const Color(0xFF4CAF50),
    animation: StyledToastAnimation.slideFromBottom,
  );
}

void showErrorToast(BuildContext context, String message) {
  _showSmartToast(
    context,
    message,
    icon: Icons.error_outline_rounded,
    color: const Color(0xFFE53935),
    animation: StyledToastAnimation.slideFromTop,
  );
}

void showWarningToast(BuildContext context, String message) {
  _showSmartToast(
    context,
    message,
    icon: Icons.warning_amber_rounded,
    color: const Color(0xFFFFC107),
    animation: StyledToastAnimation.slideFromTop,
  );
}

void _showSmartToast(
  BuildContext context,
  String message, {
  required IconData icon,
  required Color color,
  required StyledToastAnimation animation,
}) {
  final mediaQuery = MediaQuery.of(context);
  final keyboardHeight = mediaQuery.viewInsets.bottom;
  final isKeyboardOpen = keyboardHeight > 100;

  final toastWidget = Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: Colors.white, size: 22),
      ],
    ),
  );

  // Calculate alignment: above keyboard or bottom
  final alignment = Alignment(
    0.0,
    isKeyboardOpen
        ? -1.0 + (keyboardHeight / mediaQuery.size.height) * 2 + 0.15
        : 1.0 - 0.15,
  );

  showToastWidget(
    toastWidget,
    context: context,
    position: StyledToastPosition.center,
    alignment: alignment,
    animation: animation,
    reverseAnimation: StyledToastAnimation.fade,
    duration: const Duration(seconds: 3),
  );
}