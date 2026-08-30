# Implementation Plan - UI Enhancements and Settings Expansion

Enhance the Home page layout, expand Settings with currency and split preferences, implement data export, and update the application version.

## Proposed Changes

### UI Components

#### [MODIFY] [home_screen.dart](file:///C:/Users/Venkatesan. V/Desktop/GDG/lib/screens/home/home_screen.dart)
- Adjust the `SliverAppBar`'s `titlePadding` to move the "QuickSplit" text slightly higher.
- Specifically, reduce the `vertical` padding in `EdgeInsets.symmetric(horizontal: 20, vertical: 10)`.

#### [MODIFY] [settings_screen.dart](file:///C:/Users/Venkatesan. V/Desktop/GDG/lib/screens/settings/settings_screen.dart)
- Replace "Coming Soon" placeholders for Currency and Default Split with interactive pickers.
- Update the Version tile to show `1.0.0 stable`.
- Implement a realistic `_exportData` function that summarizes the current data and shows a success notification.

### Data Models & State Management

#### [MODIFY] [app_settings.dart](file:///C:/Users/Venkatesan. V/Desktop/GDG/lib/models/app_settings.dart)
- Add `currencySymbol` (String) and `defaultSplitType` (String) fields to the `AppSettings` collection.

#### [MODIFY] [theme_provider.dart](file:///C:/Users/Venkatesan. V/Desktop/GDG/lib/providers/theme_provider.dart)
- Update `AppThemeState` to include `currency` and `defaultSplit`.
- Update `ThemeNotifier` to load and save these new settings.
- Add `setCurrency` and `setDefaultSplit` methods.

## Verification Plan

### Manual Verification
- **Home Page:** Verify that the "QuickSplit" title in the app bar is positioned higher.
- **Settings Page:**
    - Open "Currency" and select between $ and Rs. Verify the choice persists.
    - Open "Default Split" and select a variation. Verify the choice persists.
    - Tap "Export Data" and verify the success message.
    - Verify the version is displayed as `1.0.0 stable`.
- **Global:** Check if the currency symbol updates in the balance cards on the Home page (if implemented to use the setting).
