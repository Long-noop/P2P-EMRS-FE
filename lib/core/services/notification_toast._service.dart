import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NotificationToastService {
  static final NotificationToastService _instance =
      NotificationToastService._internal();
  factory NotificationToastService() => _instance;
  NotificationToastService._internal();

  // ✅ FIX: Store navigatorKey to access overlay context
  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void showNotificationToast({
    required String title,
    required String message,
    required String type,
    VoidCallback? onTap,
  }) {
    // ✅ FIX: Get context from navigatorKey instead of parameter
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      print('⚠️ [NotificationToast] No navigator context available');
      return;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: _NotificationToast(
          title: title,
          message: message,
          type: type,
          onTap: () {
            overlayEntry.remove();
            onTap?.call();
          },
          onDismiss: () {
            overlayEntry.remove();
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _NotificationToast extends StatefulWidget {
  final String title;
  final String message;
  final String type;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationToast({
    required this.title,
    required this.message,
    required this.type,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<_NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case 'BOOKING_REQUEST':
        return Icons.pending_actions;
      case 'BOOKING_CONFIRMED':
        return Icons.check_circle;
      case 'BOOKING_REJECTED':
        return Icons.cancel;
      case 'BOOKING_CANCELLED':
        return Icons.event_busy;
      case 'TRIP_STARTED':
        return Icons.play_circle;
      case 'TRIP_COMPLETED':
        return Icons.task_alt;
      case 'PAYMENT_SUCCESS':
        return Icons.payments;
      case 'PAYMENT_FAILED':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case 'BOOKING_REQUEST':
        return AppColors.warning;
      case 'BOOKING_CONFIRMED':
      case 'TRIP_COMPLETED':
      case 'PAYMENT_SUCCESS':
        return AppColors.success;
      case 'BOOKING_REJECTED':
      case 'BOOKING_CANCELLED':
      case 'PAYMENT_FAILED':
        return AppColors.error;
      case 'TRIP_STARTED':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIcon(), color: _getColor(), size: 24),
                  ),

                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
