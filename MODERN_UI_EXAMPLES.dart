// Example: How to integrate Modern UI Components into your app
// This file shows practical examples of using the modern components

// import 'package:flex_pilates_studio/views/widgets/modern_components.dart';
// import 'package:flex_pilates_studio/views/widgets/modern_colors.dart';
// import 'package:flex_pilates_studio/views/widgets/modern_theme.dart';

// ============================================================================
// STEP 1: Update your main.dart
// ============================================================================

// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flex Pilates Studio',
//       theme: ModernTheme.lightTheme(),  // Use modern theme
//       darkTheme: ModernTheme.darkTheme(),
//       themeMode: ThemeMode.light,
//       home: const HomeScreen(),
//     );
//   }
// }

// ============================================================================
// STEP 2: Example Screen using Modern Components
// ============================================================================

// class SessionsScreen extends StatefulWidget {
//   const SessionsScreen({super.key});
//
//   @override
//   State<SessionsScreen> createState() => _SessionsScreenState();
// }
//
// class _SessionsScreenState extends State<SessionsScreen> {
//   int _unreadNotifications = 3;
//   bool _isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Available Sessions'),
//         elevation: 0,
//         actions: [
//           // Notification icon with animated badge
//           Padding(
//             padding: const EdgeInsets.all(ModernSpacing.md),
//             child: Stack(
//               children: [
//                 AnimatedNotificationIcon(
//                   icon: Icons.notifications_none,
//                   hasNotifications: _unreadNotifications > 0,
//                   onTap: () => _openNotifications(),
//                 ),
//                 Positioned(
//                   right: 0,
//                   top: 0,
//                   child: NotificationBadge(
//                     count: _unreadNotifications,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: _isLoading ? _buildLoadingState() : _buildSessionsList(),
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(ModernSpacing.lg),
//       itemCount: 5,
//       itemBuilder: (context, index) {
//         return Padding(
//           padding: const EdgeInsets.only(bottom: ModernSpacing.lg),
//           child: buildShimmerEffect(
//             width: double.infinity,
//             height: 120,
//             borderRadius: ModernRadius.lg,
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildSessionsList() {
//     final sessions = [
//       {'title': 'Beginner Pilates', 'time': '9:00 AM', 'coach': 'Sarah'},
//       {'title': 'Advanced Reformer', 'time': '11:00 AM', 'coach': 'John'},
//       {'title': 'Yoga Fusion', 'time': '2:00 PM', 'coach': 'Emma'},
//     ];
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(ModernSpacing.lg),
//       itemCount: sessions.length,
//       itemBuilder: (context, index) {
//         final session = sessions[index];
//         return _buildSessionCard(session);
//       },
//     );
//   }
//
//   Widget _buildSessionCard(Map<String, String> session) {
//     return GlassCard(
//       margin: const EdgeInsets.only(bottom: ModernSpacing.lg),
//       onTap: () => _showSessionDetails(session),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Session title
//           Text(
//             session['title'] ?? 'Session',
//             style: ModernTypography.titleLarge,
//           ),
//           const SizedBox(height: ModernSpacing.md),
//
//           // Session details row
//           Row(
//             children: [
//               Icon(
//                 Icons.schedule,
//                 size: 18,
//                 color: ModernColors.textSecondary,
//               ),
//               const SizedBox(width: ModernSpacing.sm),
//               Text(
//                 session['time'] ?? '',
//                 style: ModernTypography.bodySmall.copyWith(
//                   color: ModernColors.textSecondary,
//                 ),
//               ),
//               const SizedBox(width: ModernSpacing.lg),
//               Icon(
//                 Icons.person,
//                 size: 18,
//                 color: ModernColors.textSecondary,
//               ),
//               const SizedBox(width: ModernSpacing.sm),
//               Text(
//                 'with ${session['coach'] ?? ''}',
//                 style: ModernTypography.bodySmall.copyWith(
//                   color: ModernColors.textSecondary,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: ModernSpacing.lg),
//
//           // Book button
//           ModernButton(
//             label: 'Book Session',
//             width: double.infinity,
//             onPressed: () => _bookSession(session),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showSessionDetails(Map<String, String> session) {
//     showDialog(
//       context: context,
//       builder: (_) => buildGlassModal(
//         context: context,
//         title: session['title'] ?? 'Session Details',
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Time: ${session['time']}',
//               style: ModernTypography.bodyMedium,
//             ),
//             const SizedBox(height: ModernSpacing.md),
//             Text(
//               'Coach: ${session['coach']}',
//               style: ModernTypography.bodyMedium,
//             ),
//             const SizedBox(height: ModernSpacing.md),
//             Text(
//               'Description',
//               style: ModernTypography.labelMedium,
//             ),
//             const SizedBox(height: ModernSpacing.sm),
//             Text(
//               'A dynamic pilates session combining traditional and modern techniques.',
//               style: ModernTypography.bodySmall.copyWith(
//                 color: ModernColors.textSecondary,
//               ),
//             ),
//           ],
//         ),
//         footer: ModernButton(
//           label: 'Book Now',
//           onPressed: () {
//             Navigator.pop(context);
//             _bookSession(session);
//           },
//           width: double.infinity,
//         ),
//       ),
//     );
//   }
//
//   void _bookSession(Map<String, String> session) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Booked: ${session['title']}'),
//         backgroundColor: ModernColors.success,
//       ),
//     );
//   }
//
//   void _openNotifications() {
//     // Navigate to notifications screen
//   }
// }

// ============================================================================
// STEP 3: Example Sign-Up Form
// ============================================================================

// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});
//
//   @override
//   State<SignUpScreen> createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(ModernSpacing.lg),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: ModernSpacing.xl),
//
//             // Header
//             Text(
//               'Create Account',
//               style: ModernTypography.displaySmall,
//             ),
//             const SizedBox(height: ModernSpacing.md),
//             Text(
//               'Join us for the best pilates experience',
//               style: ModernTypography.bodyLarge.copyWith(
//                 color: ModernColors.textSecondary,
//               ),
//             ),
//             const SizedBox(height: ModernSpacing.xl),
//
//             // Form
//             Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   // Full Name
//                   ModernTextField(
//                     controller: _nameController,
//                     label: 'Full Name',
//                     hint: 'John Doe',
//                     prefixIcon: Icons.person,
//                   ),
//                   const SizedBox(height: ModernSpacing.lg),
//
//                   // Email
//                   ModernTextField(
//                     controller: _emailController,
//                     label: 'Email Address',
//                     hint: 'john@example.com',
//                     keyboardType: TextInputType.emailAddress,
//                     prefixIcon: Icons.email,
//                   ),
//                   const SizedBox(height: ModernSpacing.lg),
//
//                   // Password
//                   ModernTextField(
//                     controller: _passwordController,
//                     label: 'Password',
//                     hint: 'Enter a strong password',
//                     obscureText: true,
//                     prefixIcon: Icons.lock,
//                     suffixIcon: Icons.visibility_off,
//                   ),
//                   const SizedBox(height: ModernSpacing.xl),
//
//                   // Sign Up Button
//                   ModernButton(
//                     label: 'Create Account',
//                     width: double.infinity,
//                     isLoading: _isLoading,
//                     onPressed: _handleSignUp,
//                   ),
//                   const SizedBox(height: ModernSpacing.lg),
//
//                   // Sign In Link
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Already have an account? ',
//                         style: ModernTypography.bodyMedium,
//                       ),
//                       GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Text(
//                           'Sign In',
//                           style: ModernTypography.bodyMedium.copyWith(
//                             color: ModernColors.primary,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _handleSignUp() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       // Your sign-up logic here
//       await Future.delayed(const Duration(seconds: 2));
//
//       if (mounted) {
//         Navigator.pushReplacementNamed(context, '/home');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: ModernColors.error,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }

// ============================================================================
// STEP 4: Example Notification Center
// ============================================================================

// class NotificationCenterScreen extends StatefulWidget {
//   const NotificationCenterScreen({super.key});
//
//   @override
//   State<NotificationCenterScreen> createState() =>
//       _NotificationCenterScreenState();
// }
//
// class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
//   final notifications = [
//     {
//       'title': 'Session Confirmed',
//       'message': 'Your booking for Monday 9:00 AM is confirmed',
//       'time': '2 hours ago',
//       'icon': Icons.check_circle,
//       'color': ModernColors.success,
//     },
//     {
//       'title': 'New Class Available',
//       'message': 'Advanced Reformer class added this weekend',
//       'time': '5 hours ago',
//       'icon': Icons.star,
//       'color': ModernColors.secondary,
//     },
//     {
//       'title': 'Reminder',
//       'message': 'Your session starts in 30 minutes',
//       'time': '30 minutes ago',
//       'icon': Icons.notifications,
//       'color': ModernColors.warning,
//     },
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notifications'),
//         elevation: 0,
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(ModernSpacing.lg),
//         itemCount: notifications.length,
//         itemBuilder: (context, index) {
//           final notification = notifications[index];
//           return _buildNotificationCard(notification);
//         },
//       ),
//     );
//   }
//
//   Widget _buildNotificationCard(Map<String, dynamic> notification) {
//     return GlassCard(
//       margin: const EdgeInsets.only(bottom: ModernSpacing.lg),
//       child: Row(
//         children: [
//           Container(
//             width: 50,
//             height: 50,
//             decoration: BoxDecoration(
//               color: (notification['color'] as Color).withOpacity(0.1),
//               borderRadius: BorderRadius.circular(ModernRadius.md),
//             ),
//             child: Center(
//               child: Icon(
//                 notification['icon'] as IconData,
//                 color: notification['color'] as Color,
//               ),
//             ),
//           ),
//           const SizedBox(width: ModernSpacing.md),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   notification['title'] as String,
//                   style: ModernTypography.titleMedium,
//                 ),
//                 const SizedBox(height: ModernSpacing.xs),
//                 Text(
//                   notification['message'] as String,
//                   style: ModernTypography.bodySmall.copyWith(
//                     color: ModernColors.textSecondary,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: ModernSpacing.sm),
//                 Text(
//                   notification['time'] as String,
//                   style: ModernTypography.labelSmall.copyWith(
//                     color: ModernColors.textTertiary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ============================================================================
// USAGE NOTES
// ============================================================================

// 1. IMPORT PATHS:
//    All imports are commented out. When using, ensure the import paths
//    match your project structure. Typically:
//    - import 'package:flex_pilates_studio/views/widgets/modern_components.dart';

// 2. COLOR CUSTOMIZATION:
//    - Don't hardcode colors, always use ModernColors constants
//    - Use status colors for success/error/warning states
//    - Use opacity variants for subtle effects

// 3. SPACING CONSISTENCY:
//    - Always use ModernSpacing constants for padding/margin
//    - Don't hardcode pixel values
//    - Use multiples of the spacing scale

// 4. PERFORMANCE:
//    - Use const constructors where possible
//    - Avoid rebuilding StatefulWidget components unnecessarily
//    - Cache gradient definitions for repeated use

// 5. ACCESSIBILITY:
//    - Ensure sufficient color contrast ratios
//    - Provide semantic labels for icons
//    - Test with screen readers

// 6. RESPONSIVE DESIGN:
//    - Use MediaQuery.of(context).size for responsive layouts
//    - Consider different screen sizes and orientations
//    - Test on various devices

// 7. ERROR HANDLING:
//    - Always show ModernColors.error for error states
//    - Use error snackbars for user feedback
//    - Validate form inputs with clear error messages

// 8. ANIMATIONS:
//    - Use ModernCurves for smooth, consistent animations
//    - Avoid excessive animations that might slow performance
//    - Test animations on lower-end devices

// ============================================================================
