import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MailtrapService {
  static final MailtrapService _instance = MailtrapService._internal();

  factory MailtrapService() {
    return _instance;
  }

  MailtrapService._internal();

  // Configuration from environment variables
  late final String _apiToken = dotenv.get('MAILTRAP_API_TOKEN', fallback: '');
  late final String _apiUrl =
      dotenv.get('MAILTRAP_API_URL', fallback: 'https://send.api.mailtrap.io/api/send');
  late final String _fromEmail =
      dotenv.get('MAILTRAP_FROM_EMAIL', fallback: 'notifications@flexpilates.app');
  late final String _fromName =
      dotenv.get('MAILTRAP_FROM_NAME', fallback: 'Flex Pilates Studio');

  // HTTP client for making requests
  final http.Client _httpClient = http.Client();

  // Logging flag for debugging
  bool _debugLogging = kDebugMode;

  /// Initialize the service with configuration validation
  ///
  /// Throws [Exception] if required environment variables are missing
  Future<void> initialize() async {
    if (_apiToken.isEmpty) {
      throw Exception(
        'MAILTRAP_API_TOKEN is not set in .env file. '
        'Please refer to docs/MAILTRAP_SETUP_GUIDE.md for setup instructions.',
      );
    }

    _log('MailtrapService initialized successfully');
    _log('API Token: ${_apiToken.substring(0, 10)}...');
    _log('From Email: $_fromEmail');
  }

  /// Send an email using Mailtrap API
  ///
  /// Parameters:
  /// - [to]: Recipient email address
  /// - [toName]: Recipient name (optional)
  /// - [subject]: Email subject
  /// - [templateId]: Mailtrap template ID or template name
  /// - [variables]: Template variables map for variable substitution
  /// - [isHtml]: Whether to treat body as HTML (default: true)
  /// - [replyTo]: Reply-to email address (optional)
  ///
  /// Returns:
  /// - `true` if email was sent successfully
  /// - `false` if an error occurred
  ///
  /// Example:
  /// ```dart
  /// final mailtrap = MailtrapService();
  /// await mailtrap.initialize();
  /// final success = await mailtrap.sendEmail(
  ///   to: 'user@example.com',
  ///   subject: 'New Session Available',
  ///   templateId: 'session_created',
  ///   variables: {
  ///     'member_name': 'John Doe',
  ///     'session_title': 'Pilates Advanced',
  ///     'date': '2025-05-22',
  ///   },
  /// );
  /// ```
  Future<bool> sendEmail({
    required String to,
    String? toName,
    required String subject,
    required String templateId,
    required Map<String, dynamic> variables,
    bool isHtml = true,
    String? replyTo,
  }) async {
    try {
      // Validate required parameters
      if (to.isEmpty) {
        throw ArgumentError('Recipient email address (to) cannot be empty');
      }

      if (subject.isEmpty) {
        throw ArgumentError('Email subject cannot be empty');
      }

      if (templateId.isEmpty) {
        throw ArgumentError('Template ID cannot be empty');
      }

      if (_apiToken.isEmpty) {
        throw Exception(
          'MAILTRAP_API_TOKEN not configured. Please run initialize() first.',
        );
      }

      // Build the request payload
      final payload = _buildPayload(
        to: to,
        toName: toName,
        subject: subject,
        templateId: templateId,
        variables: variables,
        isHtml: isHtml,
        replyTo: replyTo,
      );

      _log('Sending email to: $to with template: $templateId');
      _log('Payload: ${jsonEncode(payload)}');

      // Make the API request
      final response = await _httpClient.post(
        Uri.parse(_apiUrl),
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );

      // Handle response
      if (response.statusCode == 200) {
        _log('Email sent successfully to: $to');
        _log('Response: ${response.body}');
        return true;
      } else {
        _logError(
          'Failed to send email to: $to',
          'Status Code: ${response.statusCode}',
          'Response: ${response.body}',
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logError(
        'Exception while sending email to: $to',
        'Error: $e',
        'StackTrace: $stackTrace',
      );
      return false;
    }
  }

  /// Send multiple emails in batch
  ///
  /// Parameters:
  /// - [recipients]: List of email recipients with template variables
  ///
  /// Returns a map of email addresses to send status (true/false)
  Future<Map<String, bool>> sendBatchEmails({
    required List<EmailRecipient> recipients,
  }) async {
    final results = <String, bool>{};

    _log('Sending batch emails to ${recipients.length} recipient(s)');

    for (final recipient in recipients) {
      final success = await sendEmail(
        to: recipient.email,
        toName: recipient.name,
        subject: recipient.subject,
        templateId: recipient.templateId,
        variables: recipient.variables,
      );

      results[recipient.email] = success;
    }

    return results;
  }

  /// Test the Mailtrap connection
  ///
  /// Sends a test email to verify the service is working
  ///
  /// Returns:
  /// - `true` if test email was sent successfully
  /// - `false` otherwise
  Future<bool> testConnection({required String testEmail}) async {
    _log('Testing Mailtrap connection with test email to: $testEmail');

    return sendEmail(
      to: testEmail,
      subject: 'Flex Pilates - Mailtrap Connection Test',
      templateId: 'session_created',
      variables: {
        'member_name': 'Test User',
        'session_title': 'Test Session',
        'date': '2025-01-20',
        'time': '10:00 AM',
        'coach_name': 'Test Coach',
        'duration': '60',
        'spots_available': '1',
        'booking_link': 'https://app.flexpilates.app',
      },
    );
  }

  /// Build the request payload for Mailtrap API
  Map<String, dynamic> _buildPayload({
    required String to,
    String? toName,
    required String subject,
    required String templateId,
    required Map<String, dynamic> variables,
    bool isHtml = true,
    String? replyTo,
  }) {
    final payload = {
      'from': {
        'email': _fromEmail,
        'name': _fromName,
      },
      'to': [
        {
          'email': to,
          if (toName != null && toName.isNotEmpty) 'name': toName,
        }
      ],
      'subject': subject,
      'template_id': templateId,
      'template_variables': variables,
    };

    if (replyTo != null && replyTo.isNotEmpty) {
      payload['reply_to'] = {
        'email': replyTo,
      };
    }

    return payload;
  }

  /// Get HTTP headers for API request
  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer $_apiToken',
      'Content-Type': 'application/json',
      'User-Agent': 'FlexPilates-MailtrapService/1.0.0',
    };
  }

  /// Log debug message
  void _log(String message) {
    if (_debugLogging) {
      debugPrint('[MailtrapService] $message');
    }
  }

  /// Log error message
  void _logError(String title, String error, String stackTrace) {
    if (_debugLogging) {
      debugPrint('[MailtrapService ERROR] $title');
      debugPrint('[MailtrapService ERROR] $error');
      debugPrint('[MailtrapService ERROR] $stackTrace');
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Model for batch email recipient
class EmailRecipient {
  final String email;
  final String? name;
  final String subject;
  final String templateId;
  final Map<String, dynamic> variables;

  EmailRecipient({
    required this.email,
    this.name,
    required this.subject,
    required this.templateId,
    required this.variables,
  });

  /// Create from JSON (for API responses or database records)
  factory EmailRecipient.fromJson(Map<String, dynamic> json) {
    return EmailRecipient(
      email: json['email'] as String,
      name: json['name'] as String?,
      subject: json['subject'] as String,
      templateId: json['templateId'] as String,
      variables: json['variables'] as Map<String, dynamic>,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'subject': subject,
      'templateId': templateId,
      'variables': variables,
    };
  }
}
