# Modern UI Components Guide

This guide explains how to use the new modern, glossy UI components that have been added to the Flutter app.

## Files Created

- **`lib/views/widgets/modern_colors.dart`** - Color system with gradients and glass effects
- **`lib/views/widgets/modern_theme.dart`** - Theme configuration, typography, spacing, and shadows
- **`lib/views/widgets/modern_components.dart`** - Reusable modern UI components

## Quick Start

### 1. Update Your MaterialApp Theme

In your `main.dart` or app configuration file, update the theme:

```dart
import 'lib/views/widgets/modern_theme.dart';

MaterialApp(
  theme: ModernTheme.lightTheme(),
  darkTheme: ModernTheme.darkTheme(),
  themeMode: ThemeMode.light,
  // ... rest of your config
)
```

### 2. Import and Use Components

```dart
import 'package:flex_pilates_studio/views/widgets/modern_components.dart';
import 'package:flex_pilates_studio/views/widgets/modern_colors.dart';
import 'package:flex_pilates_studio/views/widgets/modern_theme.dart';
```

## Color System

### Primary Colors (Deep Purple/Indigo)
- `ModernColors.primary` - Main brand color
- `ModernColors.primaryLight` / `ModernColors.primaryDark`
- `ModernColors.primaryLightest` / `ModernColors.primaryDarkest`

### Secondary Colors (Teal/Cyan)
- `ModernColors.secondary` - Accent color
- `ModernColors.secondaryLight` / `ModernColors.secondaryDark`

### Status Colors
- `ModernColors.success` / `ModernColors.error` / `ModernColors.warning` / `ModernColors.info`
- Each has `.Light`, `.Dark`, and `.Lightest` variants

### Glass Effect
```dart
ModernColors.glassDark       // 10% opacity
ModernColors.glassMedium     // 15% opacity
ModernColors.glassLight      // 25% opacity
ModernColors.glassLighter    // 35% opacity
```

### Gradients
```dart
ModernColors.primaryGradient          // Purple gradient
ModernColors.primaryToPurpleGradient  // Deep purple gradient
ModernColors.secondaryGradient        // Teal gradient
ModernColors.successGradient          // Green gradient
ModernColors.errorGradient            // Red gradient
```

## Spacing & Layout

All spacing values follow a consistent scale:

```dart
ModernSpacing.xs    = 4.0    // Extra small
ModernSpacing.sm    = 8.0    // Small
ModernSpacing.md    = 12.0   // Medium
ModernSpacing.lg    = 16.0   // Large
ModernSpacing.xl    = 24.0   // Extra large
ModernSpacing.xxl   = 32.0   // XXL
ModernSpacing.huge  = 48.0   // Huge
```

## Border Radius

```dart
ModernRadius.xs   = 4.0      // Extra small
ModernRadius.sm   = 8.0      // Small
ModernRadius.md   = 12.0     // Medium
ModernRadius.lg   = 16.0     // Large (default for cards)
ModernRadius.xl   = 24.0     // Extra large
ModernRadius.xxl  = 32.0     // XXL
ModernRadius.full = 1000.0   // Full circle
```

## Shadows & Elevation

```dart
ModernShadows.soft          // Subtle elevation
ModernShadows.medium        // Interactive elements
ModernShadows.high          // Prominent elements
ModernShadows.extraHigh     // Modals and overlays
```

Use in decorations:
```dart
BoxDecoration(
  boxShadow: ModernShadows.mediumElevation,
)
```

## Typography

Define text styles with built-in consistency:

```dart
ModernTypography.displayLarge       // 32px, bold
ModernTypography.headlineLarge      // 22px, w600
ModernTypography.titleLarge         // 16px, w600
ModernTypography.bodyLarge          // 16px, w400
ModernTypography.labelLarge         // 14px, w600
ModernTypography.bodySmall          // 12px, w400
ModernTypography.labelSmall         // 10px, w600
```

## Component Examples

### 1. GlassCard (Glassmorphism Container)

A card with blur effect and modern aesthetic:

```dart
GlassCard(
  padding: const EdgeInsets.all(ModernSpacing.lg),
  child: Text(
    'Welcome',
    style: ModernTypography.headlineSmall,
  ),
  onTap: () => print('Tapped'),
)
```

**Properties:**
- `child` - Widget to display inside
- `padding` / `margin` - Spacing
- `width` / `height` - Dimensions
- `onTap` - Tap callback
- `blurAmount` - Blur intensity (default: 10)
- `showBorder` - Display border (default: true)
- `borderGradient` - Optional gradient border

### 2. ModernButton (Gradient Button)

```dart
ModernButton(
  label: 'Book Session',
  onPressed: () => _bookSession(),
  gradient: ModernColors.primaryGradient,
)
```

**Properties:**
- `label` - Button text
- `onPressed` - Tap handler
- `gradient` - Custom gradient (default: primary)
- `width` / `height` - Dimensions
- `textStyle` - Custom text style
- `icon` - Optional icon
- `isLoading` - Show spinner (default: false)
- `isEnabled` - Enable/disable state

### 3. ModernTextField (Input Field)

```dart
ModernTextField(
  label: 'Email',
  hint: 'Enter your email',
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.email,
  onChanged: (value) => setState(() => _email = value),
)
```

**Properties:**
- `label` - Field label
- `hint` - Placeholder text
- `errorText` - Error message
- `prefixIcon` / `suffixIcon` - Icons
- `obscureText` - Hide input (for passwords)
- `maxLines` / `minLines` - Line control
- `keyboardType` - Input type
- `validator` - Validation function

### 4. NotificationBadge (Count Badge)

```dart
NotificationBadge(
  count: 5,
  backgroundColor: ModernColors.error,
  size: 24,
)
```

**Properties:**
- `count` - Number to display
- `backgroundColor` - Badge color
- `textColor` - Text color
- `size` - Badge diameter

Features:
- Automatic pulse animation when count > 0
- Shows "99+" for counts > 99
- Glassmorphic effect with blur

### 5. AnimatedNotificationIcon (Pulsing Icon)

```dart
AnimatedNotificationIcon(
  icon: Icons.notifications,
  hasNotifications: _unreadCount > 0,
  activeColor: ModernColors.primary,
  inactiveColor: ModernColors.textTertiary,
  size: 24,
  onTap: () => _openNotifications(),
)
```

**Properties:**
- `icon` - Icon to display
- `hasNotifications` - Trigger animation
- `activeColor` / `inactiveColor` - Colors
- `size` - Icon size
- `onTap` - Tap callback

Features:
- Pulses when `hasNotifications` is true
- Smooth color transitions
- Perfect for notification bell icons

## Helper Functions

### buildGlassModal

Create a modal with glassmorphism:

```dart
showDialog(
  context: context,
  builder: (_) => buildGlassModal(
    context: context,
    title: 'Confirm Booking',
    content: Text('Book this session?'),
    footer: ModernButton(
      label: 'Confirm',
      onPressed: () => Navigator.pop(context),
    ),
    onClose: () => Navigator.pop(context),
  ),
)
```

### buildShimmerEffect

Loading skeleton placeholder:

```dart
buildShimmerEffect(
  width: 200,
  height: 100,
  borderRadius: ModernRadius.lg,
)
```

### buildSoftShadow

Create custom soft shadows:

```dart
BoxDecoration(
  boxShadow: [
    buildSoftShadow(
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ],
)
```

## Animation Curves

Smooth animations with custom curves:

```dart
ModernCurves.easeInSubtle      // Subtle entrance
ModernCurves.easeOutSubtle     // Subtle exit
ModernCurves.easeInOutSmooth   // Smooth interaction
ModernCurves.snappy            // Quick feedback
ModernCurves.bouncy            // Spring-like effect
```

Example:
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: ModernCurves.easeInOutSmooth,
  color: _isHovered ? Colors.blue : Colors.gray,
)
```

## Real-World Examples

### Example 1: Notification Center Header

```dart
Container(
  padding: const EdgeInsets.all(ModernSpacing.lg),
  child: Row(
    children: [
      Text(
        'Notifications',
        style: ModernTypography.headlineSmall,
      ),
      const Spacer(),
      Stack(
        children: [
          Icon(
            Icons.notifications,
            size: 24,
            color: ModernColors.textSecondary,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: NotificationBadge(count: _unreadCount),
          ),
        ],
      ),
    ],
  ),
)
```

### Example 2: Session Booking Card

```dart
GlassCard(
  margin: const EdgeInsets.all(ModernSpacing.md),
  onTap: () => _showSessionDetails(session),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        session.title,
        style: ModernTypography.titleLarge,
      ),
      const SizedBox(height: ModernSpacing.sm),
      Text(
        session.time,
        style: ModernTypography.bodyMedium.copyWith(
          color: ModernColors.textSecondary,
        ),
      ),
      const SizedBox(height: ModernSpacing.lg),
      ModernButton(
        label: 'Book Now',
        onPressed: () => _bookSession(session),
        width: double.infinity,
      ),
    ],
  ),
)
```

### Example 3: Loading State with Shimmer

```dart
ListView.builder(
  itemCount: 5,
  itemBuilder: (context, index) {
    return Padding(
      padding: const EdgeInsets.all(ModernSpacing.md),
      child: buildShimmerEffect(
        width: double.infinity,
        height: 80,
        borderRadius: ModernRadius.lg,
      ),
    );
  },
)
```

### Example 4: Form with Modern Styling

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      ModernTextField(
        label: 'Full Name',
        hint: 'John Doe',
        onChanged: (value) => _name = value,
      ),
      const SizedBox(height: ModernSpacing.lg),
      ModernTextField(
        label: 'Email',
        hint: 'john@example.com',
        keyboardType: TextInputType.emailAddress,
        prefixIcon: Icons.email,
      ),
      const SizedBox(height: ModernSpacing.lg),
      ModernButton(
        label: 'Submit',
        onPressed: _submitForm,
        width: double.infinity,
      ),
    ],
  ),
)
```

## Performance Considerations

### Optimization Tips

1. **Use `const` constructors** wherever possible:
   ```dart
   const GlassCard(child: Text('Optimized'))
   ```

2. **Avoid unnecessary rebuilds** with StatefulWidget components:
   ```dart
   // Good - only rebuild when needed
   AnimatedNotificationIcon(
     hasNotifications: _unreadCount > 0,
   )
   ```

3. **Use provided spacing/radius constants** instead of hardcoding:
   ```dart
   // Good - reuses constants
   padding: const EdgeInsets.all(ModernSpacing.lg),
   
   // Avoid - hardcoded values
   padding: const EdgeInsets.all(16.0),
   ```

4. **Cache gradient definitions** in variables for repeated use:
   ```dart
   final gradient = ModernColors.primaryGradient;
   ```

## Integration Checklist

- [ ] Update `MaterialApp` with `ModernTheme.lightTheme()`
- [ ] Import modern components in screens that use them
- [ ] Replace hardcoded spacing with `ModernSpacing` constants
- [ ] Replace hardcoded colors with `ModernColors`
- [ ] Replace custom buttons with `ModernButton`
- [ ] Add notification badges to notification UI
- [ ] Use `AnimatedNotificationIcon` for notification bell
- [ ] Add `GlassCard` for modern cards
- [ ] Use `ModernTextField` for all form inputs
- [ ] Add loading skeletons with `buildShimmerEffect`

## Migration from Existing Theme

The new modern theme is **compatible** with the existing theme. You can:

1. Keep using existing components while gradually migrating to modern ones
2. Mix old and new components in the same screen
3. Gradually refactor screens to use modern components

The existing `AppColors` and `AppTextStyles` are still available, but the new `ModernColors` and `ModernTypography` provide a more cohesive, modern design system.

## Dark Mode Support

Dark theme is ready for implementation:

```dart
MaterialApp(
  theme: ModernTheme.lightTheme(),
  darkTheme: ModernTheme.darkTheme(),
  themeMode: ThemeMode.system, // Follows device setting
)
```

Currently set to light mode. Uncomment dark theme when ready to deploy dark mode.

## Troubleshooting

### Components not showing up?
- Ensure you've imported the correct file
- Check that `flutter pub get` has been run
- Verify imports are using relative paths correctly

### Blur effect not working?
- `BackdropFilter` requires a physical device or high-end emulator
- Low-end emulators may not support the blur effect
- The glassmorphic effect gracefully degrades

### Text overflow?
- Use `Expanded` or `SizedBox` to constrain width
- Check that parent has defined width constraints
- Use `maxLines` and `overflow` properties

### Performance issues?
- Reduce number of animated components on screen
- Use `const` constructors to prevent rebuilds
- Profile with Flutter DevTools to identify bottlenecks

## Support

For issues or questions about these components, refer to:
- Flutter Material 3 documentation
- Google Fonts documentation (for typography)
- Flutter Shadows and Elevation guide

## Next Steps

1. Add these components to your screens incrementally
2. Test on various devices and screen sizes
3. Gather feedback from team members
4. Customize colors/spacing to match brand guidelines
5. Consider adding animations for micro-interactions
