import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../widgets/modern_components.dart';
import '../widgets/modern_colors.dart';
import '../widgets/modern_theme.dart';

/// Notification preferences screen for managing notification settings
/// Features: Toggle channels (email, push, in-app), toggle event types, save preferences
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late NotificationPreferences _preferences;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    try {
      final controller = context.read<NotificationController>();
      final userId = controller.notifications.isNotEmpty
          ? controller.notifications.first.memberId
          : 'unknown';

      final prefs = await controller.getUserPreferences(userId);
      setState(() {
        _preferences = prefs;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: ${e.toString()}')),
        );
      }
    }
  }

  void _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      await context
          .read<NotificationController>()
          .updateNotificationPreferences(_preferences);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(ModernSpacing.lg),
              decoration: BoxDecoration(
                gradient: ModernColors.primaryGradient,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notification Settings',
                    style: ModernTypography.headlineLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Settings Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ModernSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Channels Section
                    _buildSectionHeader(
                      'Notification Channels',
                      'Choose how you want to receive notifications',
                    ),
                    const SizedBox(height: ModernSpacing.lg),
                    _buildChannelToggle(
                      'Email Notifications',
                      'Receive notifications via email',
                      NotificationChannel.EMAIL,
                      Icons.email,
                    ),
                    const SizedBox(height: ModernSpacing.md),
                    _buildChannelToggle(
                      'Push Notifications',
                      'Receive notifications on your device',
                      NotificationChannel.PUSH,
                      Icons.notifications_active,
                    ),
                    const SizedBox(height: ModernSpacing.md),
                    _buildChannelToggle(
                      'In-App Notifications',
                      'See notifications within the app',
                      NotificationChannel.IN_APP,
                      Icons.chat_bubble,
                    ),

                    const SizedBox(height: ModernSpacing.xl),

                    // Notification Types Section
                    _buildSectionHeader(
                      'Notification Types',
                      'Select which events you want to be notified about',
                    ),
                    const SizedBox(height: ModernSpacing.lg),
                    _buildEventTypeToggle(
                      'Coach Session Created',
                      'New sessions from coaches you follow',
                      NotificationEvent.COACH_SESSION_CREATED,
                      Icons.event,
                    ),
                    const SizedBox(height: ModernSpacing.md),
                    _buildEventTypeToggle(
                      'Session Spot Available',
                      'A spot became available in a session',
                      NotificationEvent.SESSION_SPOT_AVAILABLE,
                      Icons.event_available,
                    ),
                    const SizedBox(height: ModernSpacing.md),
                    _buildEventTypeToggle(
                      'Waitlist Available',
                      'You can book from the waitlist',
                      NotificationEvent.WAITLIST_AVAILABLE,
                      Icons.assignment,
                    ),
                    const SizedBox(height: ModernSpacing.md),
                    _buildEventTypeToggle(
                      'Session Cancelled',
                      'A session you\'re booked for was cancelled',
                      NotificationEvent.SESSION_CANCELLED,
                      Icons.cancel,
                    ),
                    const SizedBox(height: ModernSpacing.md),
                    _buildEventTypeToggle(
                      'Booking Confirmed',
                      'Your booking has been confirmed',
                      NotificationEvent.BOOKING_CONFIRMED,
                      Icons.check_circle,
                    ),

                    const SizedBox(height: ModernSpacing.xl),

                    // Save Button
                    ModernButton(
                      label: 'Save Preferences',
                      onPressed: _isSaving ? null : _savePreferences,
                      isLoading: _isSaving,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ModernTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: ModernSpacing.sm),
        Text(
          subtitle,
          style: ModernTypography.bodyMedium.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelToggle(
    String title,
    String description,
    NotificationChannel channel,
    IconData icon,
  ) {
    bool isEnabled = _isChannelEnabled(channel);

    return GlassCard(
      padding: const EdgeInsets.all(ModernSpacing.md),
      onTap: () {
        setState(() {
          _preferences = _preferences.copyWith(
            enabledChannels: isEnabled
                ? _preferences.enabledChannels
                    .where((c) => c != channel)
                    .toList()
                : [..._preferences.enabledChannels, channel],
          );
        });
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? ModernColors.primaryGradient
                  : LinearGradient(
                      colors: [
                        Colors.grey[200]!,
                        Colors.grey[100]!,
                      ],
                    ),
              borderRadius: BorderRadius.circular(ModernRadius.lg),
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(width: ModernSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ModernTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ModernSpacing.xs),
                Text(
                  description,
                  style: ModernTypography.labelMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 32,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? LinearGradient(
                      colors: [Colors.green.shade300, Colors.green.shade600],
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade400],
                    ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  alignment:
                      isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeToggle(
    String title,
    String description,
    NotificationEvent event,
    IconData icon,
  ) {
    bool isEnabled = _isEventTypeEnabled(event);

    return GlassCard(
      padding: const EdgeInsets.all(ModernSpacing.md),
      onTap: () {
        setState(() {
          _preferences = _preferences.copyWith(
            enabledEventTypes: isEnabled
                ? _preferences.enabledEventTypes
                    .where((e) => e != event)
                    .toList()
                : [..._preferences.enabledEventTypes, event],
          );
        });
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(ModernRadius.lg),
              border: Border.all(
                color: isEnabled
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.blue : Colors.grey[600],
            ),
          ),
          const SizedBox(width: ModernSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ModernTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ModernSpacing.xs),
                Text(
                  description,
                  style: ModernTypography.labelMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: isEnabled,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(
                  enabledEventTypes: value ?? false
                      ? [..._preferences.enabledEventTypes, event]
                      : _preferences.enabledEventTypes
                          .where((e) => e != event)
                          .toList(),
                );
              });
            },
            activeColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ModernRadius.sm),
            ),
          ),
        ],
      ),
    );
  }

  bool _isChannelEnabled(NotificationChannel channel) {
    return _preferences.enabledChannels.contains(channel);
  }

  bool _isEventTypeEnabled(NotificationEvent event) {
    return _preferences.enabledEventTypes.contains(event);
  }
}
