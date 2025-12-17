import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';
import '../storage/storage_service.dart';

/// Socket service for real-time notifications
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StorageService _storageService = StorageService();
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

  // Stream controllers
  final _connectionController = StreamController<bool>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get bookingUpdateStream =>
      _bookingUpdateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Connect to WebSocket server
  Future<void> connect(String serverUrl) async {
    if (_socket != null && _socket!.connected) {
      _logger.i('Socket already connected');
      return;
    }

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _logger.w('No auth token available for socket connection');
        return;
      }

      _socket = IO.io(
        '$serverUrl/notifications',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .build(),
      );

      _setupListeners();
      _socket!.connect();

      _logger.i('Socket connecting to $serverUrl/notifications');
    } catch (e, stackTrace) {
      _logger.e('Socket connection error', error: e, stackTrace: stackTrace);
    }
  }

  void _setupListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _logger.i('✅ Socket connected successfully');
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      _logger.w('❌ Socket disconnected');
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      _logger.e('🔴 Socket connection error: $error');
      _connectionController.add(false);
    });

    _socket!.onError((error) {
      _logger.e('🔴 Socket error: $error');
    });

    // Connection confirmation
    _socket!.on('connected', (data) {
      _logger.d('✅ Connection confirmed: $data');
    });

    // Notification events - matching backend event names
    _socket!.on('booking_request', (data) {
      _logger.i('🔔 Received booking_request notification');
      _logger.d('Booking request data: $data');
      _notificationController.add({'type': 'BOOKING_REQUEST', 'data': data});
    });

    _socket!.on('booking_confirmed', (data) {
      _logger.i('🔔 Received booking_confirmed notification');
      _logger.d('Booking confirmed data: $data');
      _notificationController.add({'type': 'BOOKING_CONFIRMED', 'data': data});
    });

    _socket!.on('booking_rejected', (data) {
      _logger.i('🔔 Received booking_rejected notification');
      _logger.d('Booking rejected data: $data');
      _notificationController.add({'type': 'BOOKING_REJECTED', 'data': data});
    });

    _socket!.on('booking_cancelled', (data) {
      _logger.i('🔔 Received booking_cancelled notification');
      _logger.d('Booking cancelled data: $data');
      _notificationController.add({'type': 'BOOKING_CANCELLED', 'data': data});
    });

    _socket!.on('trip_started', (data) {
      _logger.i('🔔 Received trip_started notification');
      _logger.d('Trip started data: $data');
      _notificationController.add({'type': 'TRIP_STARTED', 'data': data});
    });

    _socket!.on('trip_completed', (data) {
      _logger.i('🔔 Received trip_completed notification');
      _logger.d('Trip completed data: $data');
      _notificationController.add({'type': 'TRIP_COMPLETED', 'data': data});
    });

    _socket!.on('payment_success', (data) {
      _logger.i('🔔 Received payment_success notification');
      _logger.d('Payment success data: $data');
      _notificationController.add({'type': 'PAYMENT_SUCCESS', 'data': data});
    });

    _socket!.on('payment_failed', (data) {
      _logger.i('🔔 Received payment_failed notification');
      _logger.d('Payment failed data: $data');
      _notificationController.add({'type': 'PAYMENT_FAILED', 'data': data});
    });

    // Booking status changes
    _socket!.on('booking_status_changed', (data) {
      _logger.i('📊 Received booking_status_changed event');
      _logger.d('Status changed data: $data');
      _bookingUpdateController.add(data);
    });
  }

  /// Subscribe to specific booking updates
  void subscribeToBooking(String bookingId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('subscribe_booking', {'bookingId': bookingId});
      _logger.i('📌 Subscribed to booking: $bookingId');
    } else {
      _logger.w('Cannot subscribe to booking - socket not connected');
    }
  }

  /// Unsubscribe from booking updates
  void unsubscribeFromBooking(String bookingId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('unsubscribe_booking', {'bookingId': bookingId});
      _logger.i('📌 Unsubscribed from booking: $bookingId');
    } else {
      _logger.w('Cannot unsubscribe from booking - socket not connected');
    }
  }

  /// Disconnect from socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _logger.i('🔌 Socket disconnected and disposed');
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _connectionController.close();
    _notificationController.close();
    _bookingUpdateController.close();
    _logger.d('Socket service disposed - all streams closed');
  }
}
