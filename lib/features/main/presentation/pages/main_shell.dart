import 'package:fe_capstone_project/features/auth/domain/entities/user.dart';
import 'package:fe_capstone_project/features/auth/presentation/pages/profile.dart';
import 'package:fe_capstone_project/features/booking/presentation/pages/owner_booking_page.dart';
import 'package:fe_capstone_project/features/booking/presentation/pages/renter_booking_page.dart';
import 'package:fe_capstone_project/features/notification/presentation/pages/notification_pages.dart';
import 'package:fe_capstone_project/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:fe_capstone_project/features/notification/presentation/bloc/notification_state.dart';
import 'package:fe_capstone_project/features/notification/presentation/bloc/notification_event.dart';
import 'package:fe_capstone_project/features/renter/presentation/pages/become_owner_page.dart';
import 'package:fe_capstone_project/features/vehicle/presentation/pages/browse_vehices_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/home_page.dart';
import '../../../owner_vehicle/presentation/pages/owner_profile_page.dart';
import '../../../owner_vehicle/presentation/pages/owner_dashboard_page.dart';

/// Main Shell with Bottom Navigation Bar
/// Updated to support ShellRoute with child widget and notification badge
class MainShell extends StatefulWidget {
  final int initialIndex;
  final Widget? child; // Add child parameter for ShellRoute

  const MainShell({
    super.key,
    this.initialIndex = 0,
    this.child, // Optional child from ShellRoute
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  final SocketService _socketService = sl<SocketService>();
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _setupNotificationListener();
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update index when changed from router
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _setupNotificationListener() {
    // Listen for new notifications via WebSocket
    _notificationSubscription = _socketService.notificationStream.listen((_) {
      // Reload notification count when new notification arrives
      if (mounted) {
        context.read<NotificationBloc>().add(const LoadNotificationsEvent());
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate using GoRouter
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        // Check if user is owner/admin
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          final isOwner = authState.user.isOwner || authState.user.isAdmin;
          if (isOwner) {
            context.go('/owner');
          } else {
            context.go('/become-owner');
          }
        }
        break;
      case 2:
        context.go('/bookings');
        break;
      case 3:
        context.go('/notifications');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          final isOwner = user?.isOwner == true || user?.isAdmin == true;

          return Scaffold(
            // Use child from ShellRoute if provided, otherwise use IndexedStack fallback
            body: widget.child ?? _buildFallbackBody(isOwner),
            bottomNavigationBar: _buildBottomNavBar(isOwner),
          );
        },
      ),
    );
  }

  // Fallback for backward compatibility (when not using ShellRoute)
  Widget _buildFallbackBody(bool isOwner) {
    final pages = [
      const BrowseVehiclesPage(),
      if (isOwner) const OwnerDashboardPage() else const BecomeOwnerPage(),
      const RenterBookingsPage(),
      const NotificationsPage(),
      const ProfilePage(),
    ];

    return IndexedStack(index: _currentIndex, children: pages);
  }

  Widget _buildBottomNavBar(bool isOwner) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
              ),
              _buildNavItem(
                index: 1,
                icon: isOwner ? Icons.two_wheeler_outlined : Icons.add_business,
                activeIcon: isOwner
                    ? Icons.two_wheeler_outlined
                    : Icons.add_business,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.bookmark_outline,
                activeIcon: Icons.bookmark,
              ),
              _buildNavItemWithBadge(
                index: 3,
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(
          isActive ? activeIcon : icon,
          size: 28,
          color: isActive ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            int unreadCount = 0;

            if (state is NotificationsLoaded) {
              unreadCount = state.unreadCount;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 28,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
