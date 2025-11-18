// import 'package:flutter/material.dart';
// import 'package:flutter_styled_toast/flutter_styled_toast.dart';

// void showSuccessToast(BuildContext context, String message) {
//   _showSmartToast(
//     context,
//     message,
//     icon: Icons.check_circle_rounded,
//     color: const Color(0xFF4CAF50),
//     animation: StyledToastAnimation.slideFromBottom,
//   );
// }

// void showErrorToast(BuildContext context, String message) {
//   _showSmartToast(
//     context,
//     message,
//     icon: Icons.error_outline_rounded,
//     color: const Color(0xFFE53935),
//     animation: StyledToastAnimation.slideFromTop,
//   );
// }

// void showWarningToast(BuildContext context, String message) {
//   _showSmartToast(
//     context,
//     message,
//     icon: Icons.warning_amber_rounded,
//     color: const Color(0xFFFFC107),
//     animation: StyledToastAnimation.slideFromTop,
//   );
// }

// void _showSmartToast(
//   BuildContext context,
//   String message, {
//   required IconData icon,
//   required Color color,
//   required StyledToastAnimation animation,
// }) {
//   final mediaQuery = MediaQuery.of(context);
//   final keyboardHeight = mediaQuery.viewInsets.bottom;
//   final isKeyboardOpen = keyboardHeight > 100;

//   final toastWidget = Container(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//     decoration: BoxDecoration(
//       color: color,
//       borderRadius: BorderRadius.circular(10),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.15),
//           blurRadius: 6,
//           offset: const Offset(0, 3),
//         ),
//       ],
//     ),
//     child: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Flexible(
//           child: Text(
//             message,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         const SizedBox(width: 10),
//         Icon(icon, color: Colors.white, size: 22),
//       ],
//     ),
//   );

//   // Calculate alignment: above keyboard or bottom
//   final alignment = Alignment(
//     0.0,
//     isKeyboardOpen
//         ? -1.0 + (keyboardHeight / mediaQuery.size.height) * 2 + 0.15
//         : 1.0 - 0.15,
//   );

//   showToastWidget(
//     toastWidget,
//     context: context,
//     position: StyledToastPosition.center,
//     alignment: alignment,
//     animation: animation,
//     reverseAnimation: StyledToastAnimation.fade,
//     duration: const Duration(seconds: 3),
//   );
// }

import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

/// Success Toast: Bottom → Above keyboard when open
void showSuccessToast(BuildContext context, String message) {
  _showSmartToast(
    context,
    message,
    icon: Icons.check_circle_rounded,
    color: const Color(0xFF4CAF50),
    animation: StyledToastAnimation.slideFromBottom,
    isSuccess: true,
  );
}

/// Error Toast: Always at Top
void showErrorToast(BuildContext context, String message) {
  _showSmartToast(
    context,
    message,
    icon: Icons.error_outline_rounded,
    color: const Color(0xFFE53935),
    animation: StyledToastAnimation.slideFromTop,
    isSuccess: false,
  );
}

/// Warning Toast: Always at Top
void showWarningToast(BuildContext context, String message) {
  _showSmartToast(
    context,
    message,
    icon: Icons.warning_amber_rounded,
    color: const Color(0xFFFFC107),
    animation: StyledToastAnimation.slideFromTop,
    isSuccess: false,
  );
}

/// Unified toast logic
void _showSmartToast(
  BuildContext context,
  String message, {
  required IconData icon,
  required Color color,
  required StyledToastAnimation animation,
  required bool isSuccess,
}) {
  final media = MediaQuery.of(context);
  final keyboardHeight = media.viewInsets.bottom;
  final isKeyboardOpen = keyboardHeight > 100;

  // Build Toast UI
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

  // Decide alignment based on type and keyboard
  Alignment alignment;

  if (isSuccess) {
    if (isKeyboardOpen) {
      // SUCCESS + KEYBOARD: Show just above keyboard
      final double safeY = -1.0 +
          (keyboardHeight / media.size.height) * 2 +
          0.08; // 8% padding from keyboard
      alignment = Alignment(0.0, safeY);
    } else {
      // SUCCESS + NO KEYBOARD: Bottom of screen
      alignment = const Alignment(0.0, 0.85); // ~15% from bottom
    }
  } else {
    // ERROR & WARNING: Always at top
    alignment = Alignment.topCenter;
  }

  // Show the toast
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