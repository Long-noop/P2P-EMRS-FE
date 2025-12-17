import 'dart:io';
import 'package:fe_capstone_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fe_capstone_project/features/auth/presentation/bloc/auth_event.dart';
import 'package:fe_capstone_project/features/auth/presentation/bloc/auth_state.dart';
import 'package:fe_capstone_project/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:fe_capstone_project/features/notification/presentation/bloc/notification_event.dart';
import 'package:fe_capstone_project/features/notification/presentation/widgets/notification_listener.dart';
import 'package:fe_capstone_project/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/socket_service.dart';
import 'core/services/fcm_service.dart';
import 'core/storage/storage_service.dart';
import 'features/notification/domain/usecases/notification_usecases.dart';
import 'injection_container.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Global logger instance
final Logger _logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    _logger.i('🚀 Starting application initialization');

    // Initialize Firebase
    _logger.d('Initializing Firebase');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logger.i('✅ Firebase initialized successfully');

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _logger.d('Screen orientation set to portrait only');

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _logger.d('System UI overlay style configured');

    // Initialize dependency injection
    _logger.d('Initializing dependency injection');
    await di.init();
    _logger.i('✅ Dependency injection initialized');

    // Initialize FCM (mobile only)
    if (!kIsWeb) {
      await di.sl<FcmService>().initialize();
      _logger.i('✅ FCM initialized');
    } else {
      _logger.i('⚠️ Running on WEB - FCM skipped, using WebSocket only');
    }

    _logger.i('🎉 Application initialization complete');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    _logger.e(
      '❌ Fatal error during app initialization',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SocketService _socketService = di.sl<SocketService>();
  final StorageService _storageService = di.sl<StorageService>();
  final FcmService _fcmService = di.sl<FcmService>();

  @override
  void initState() {
    super.initState();
    _logger.d('MyApp state initialized');
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _logger.i('Checking user authentication status');

      // Check if user is logged in
      final isLoggedIn = await _storageService.isLoggedIn();

      if (isLoggedIn) {
        _logger.i('✅ User is logged in, initializing services');

        // Connect to WebSocket
        // TODO: Replace with your actual server URL
        const serverUrl = 'http://your-server-url.com';
        _logger.d('Connecting to WebSocket server: $serverUrl');
        await _socketService.connect(serverUrl);

        // Setup FCM callbacks
        _setupFcmCallbacks();

        // Register FCM token with backend
        await _registerFcmToken();
      } else {
        _logger.i('User not logged in, skipping service initialization');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error initializing services',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = _fcmService.fcmToken;
      if (fcmToken != null) {
        _logger.i('FCM token available: ${fcmToken.substring(0, 20)}...');

        final platform = Platform.isIOS ? 'ios' : 'android';
        _logger.d('Registering FCM token with backend (platform: $platform)');

        // Register FCM token with backend
        final registerUseCase = di.sl<RegisterFcmTokenUseCase>();
        final result = await registerUseCase(
          RegisterFcmTokenParams(token: fcmToken, platform: platform),
        );

        result.fold(
          (failure) {
            _logger.w('Failed to register FCM token: ${failure.message}');
          },
          (_) {
            _logger.i('✅ FCM token registered successfully');
          },
        );
      } else {
        _logger.w('FCM token not available');
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error registering FCM token',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _setupFcmCallbacks() {
    _logger.d('Setting up FCM callbacks');

    // Handle notification taps (when app is in background/terminated)
    _fcmService.onNotificationTapped = (message) {
      _logger.i('📱 Notification tapped');
      _logger.d('Message data: ${message.data}');

      // Navigate to appropriate screen based on notification data
      final bookingId = message.data['bookingId'];
      if (bookingId != null) {
        _logger.i('Navigating to booking: $bookingId');
        // TODO: Navigate to booking detail
        // Use GlobalKey<NavigatorState> or router to navigate
      }
    };

    // Handle foreground notifications
    _fcmService.onForegroundMessage = (message) {
      _logger.i('📬 Foreground FCM message received');
      _logger.d('Title: ${message.notification?.title}');
      _logger.d('Body: ${message.notification?.body}');
      // The local notification is already shown by FcmService
      // You can add additional handling here if needed
    };

    _logger.i('✅ FCM callbacks configured');
  }

  @override
  void dispose() {
    _logger.d('MyApp disposing - disconnecting socket');
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth Bloc - Global
        BlocProvider<AuthBloc>(
          create: (_) {
            _logger.d('Creating AuthBloc');
            return di.sl<AuthBloc>()..add(const AuthCheckRequested());
          },
        ),
        // Notification Bloc - Global
        BlocProvider<NotificationBloc>(
          create: (_) {
            _logger.d('Creating NotificationBloc');
            return di.sl<NotificationBloc>()
              ..add(const LoadNotificationsEvent());
          },
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            _logger.i('✅ User authenticated: ${state.user.email}');

            // User logged in - connect socket
            if (!_socketService.isConnected) {
              _logger.d('Socket not connected, attempting connection');
              // TODO: Replace with your actual server URL
              const serverUrl = 'http://your-server-url.com';
              await _socketService.connect(serverUrl);
            } else {
              _logger.d('Socket already connected');
            }

            // Register FCM token
            await _registerFcmToken();

            // Load notifications
            _logger.d('Loading user notifications');
            context.read<NotificationBloc>().add(
              const LoadNotificationsEvent(),
            );
          } else if (state is AuthUnauthenticated) {
            _logger.i('User unauthenticated, disconnecting socket');
            // User logged out - disconnect socket and unregister FCM
            _socketService.disconnect();

            // Unregister FCM token
            final fcmToken = _fcmService.fcmToken;
            if (fcmToken != null) {
              final unregisterUseCase = di.sl<UnregisterFcmTokenUseCase>();
              await unregisterUseCase(UnregisterFcmTokenParams(fcmToken));
            }
          } else if (state is AuthLoading) {
            _logger.d('Auth state: Loading');
          } else if (state is AuthInitial) {
            _logger.d('Auth state: Initial');
          }
        },
        child: MaterialApp.router(
          title: 'P2P Electric Motorbike Rental',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            // Wrap with NotificationListenerWidget for real-time updates
            return NotificationListenerWidget(child: child ?? const SizedBox());
          },
        ),
      ),
    );
  }
}
