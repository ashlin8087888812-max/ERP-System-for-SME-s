# ERP/SCM Design System Documentation

## Color System

### Primary Colors
```dart
// Slate - Professional & Trust
primary: #0F172A (Slate 900)
primaryLight: #334155 (Slate 700)
primaryDark: #020617 (Slate 950)
```

### Accent Colors
```dart
// Amber - Attention & Action
accent: #F59E0B (Amber 500)
accentLight: #FCD34D (Amber 300)
accentDark: #D97706 (Amber 600)
```

### Functional Colors
```dart
success: #10B981 (Emerald 500)
error: #EF4444 (Red 500)
warning: #F97316 (Orange 500)
info: #3B82F6 (Blue 500)
```

### Neutral Colors
```dart
// Light Mode
backgroundLight: #F1F5F9 (Slate 100)
surfaceLight: #FFFFFF (White)
textPrimaryLight: #0F172A (Slate 900)
textSecondaryLight: #64748B (Slate 500)
borderLight: #E2E8F0 (Slate 200)

// Dark Mode
backgroundDark: #0F172A (Slate 900)
surfaceDark: #1E293B (Slate 800)
textPrimaryDark: #F8FAFC (Slate 50)
textSecondaryDark: #94A3B8 (Slate 400)
borderDark: #334155 (Slate 700)
```

---

## Typography

### Font Family
- **Primary**: Inter (Google Fonts)
- **Fallback**: System default

### Text Styles

```dart
// Display
displayLarge: 32px, Bold, -0.5 letter-spacing
displayMedium: 28px, Bold, -0.5 letter-spacing
displaySmall: 24px, Semi-bold

// Headings
headlineMedium: 20px, Semi-bold
titleMedium: 16px, Semi-bold

// Body
bodyLarge: 16px, Regular
bodyMedium: 14px, Regular

// Labels
labelLarge: 14px, Semi-bold, 0.5 letter-spacing (buttons)
labelSmall: 12px, Medium, 0.5 letter-spacing (chips)
```

---

## Spacing & Dimensions

### Padding & Margins
```dart
p4: 4px
p8: 8px
p12: 12px
p16: 16px
p20: 20px
p24: 24px
p32: 32px
p48: 48px
```

### Border Radius
```dart
r4: 4px (small elements)
r8: 8px (buttons, inputs)
r12: 12px (cards)
r16: 16px (large cards)
r24: 24px (modals)
rFull: 999px (pills)
```

### Widget Heights
```dart
buttonHeight: 48px (minimum tap target)
inputHeight: 48px
iconSmall: 16px
iconMedium: 24px
iconLarge: 32px
```

---

## Components

### IndustrialCard
**Usage**: Container for grouped content

**Props**:
- `child`: Widget
- `padding`: EdgeInsetsGeometry (default: 16px all)
- `onTap`: VoidCallback (optional)
- `backgroundColor`: Color (optional)
- `hasBorder`: bool (default: true)

**Styling**:
- Border radius: 12px
- Border: 1px solid (light/dark border color)
- Elevation: 0 (flat design)
- Tap ripple effect

---

### StatusChip
**Usage**: Status indicators

**Props**:
- `label`: String
- `status`: ChipStatus (success, warning, error, info, neutral)

**Styling**:
- Padding: 8px horizontal, 4px vertical
- Border radius: 4px
- Background: status color at 10% opacity
- Border: status color at 20% opacity
- Text: Uppercase, 10px, bold

**Color Mapping**:
- Success → Green (#10B981)
- Warning → Orange (#F97316)
- Error → Red (#EF4444)
- Info → Blue (#3B82F6)
- Neutral → Gray (#64748B)

---

### MetricTile
**Usage**: Dashboard metric cards

**Props**:
- `label`: String
- `value`: String
- `icon`: IconData
- `color`: Color (optional)
- `trend`: String (optional, e.g., "+12%")
- `isPositiveTrend`: bool (default: true)

**Layout**:
- Icon + Trend badge (top row)
- Large value (center)
- Label (bottom)

**Styling**:
- Uses IndustrialCard as base
- Icon size: 24px
- Value: h2 style (24px, bold)
- Trend badge: 10px, rounded, color-coded

---

### ScannerWidget
**Usage**: QR/Barcode scanning

**Props**:
- `onScan`: Function(String code)
- `overlayText`: String (default: "Align QR/Barcode within frame")

**Features**:
- Camera preview (full screen)
- Overlay frame with amber corners
- Torch toggle button (top-right)
- Instruction text (bottom)
- Auto-debounce (2 seconds between scans)

**Styling**:
- Overlay color: Black at 80% opacity
- Frame color: Amber (#F59E0B)
- Frame size: 300x300px
- Corner length: 30px
- Border width: 10px

---

## Patterns

### Progress Bars
```dart
LinearProgressIndicator(
  value: 0.65,
  minHeight: 8,
  backgroundColor: AppColors.borderLight,
  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
)
```

### Dividers
```dart
Divider() // Default Material divider
```

### Buttons

#### Primary Button (ElevatedButton)
```dart
ElevatedButton.icon(
  onPressed: () {},
  icon: Icon(Icons.check_circle),
  label: Text('Complete'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary, // or success/accent
    foregroundColor: Colors.white,
    minimumSize: Size.fromHeight(48),
  ),
)
```

#### Secondary Button (OutlinedButton)
```dart
OutlinedButton.icon(
  onPressed: () {},
  icon: Icon(Icons.navigation),
  label: Text('Navigate'),
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.info,
    side: BorderSide(color: AppColors.info),
    minimumSize: Size.fromHeight(48),
  ),
)
```

### Input Fields
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Enter quantity',
    suffixText: 'units',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
)
```

---

## Layout Patterns

### Dashboard Metrics Grid
```dart
GridView.count(
  crossAxisCount: 2,
  mainAxisSpacing: 16,
  crossAxisSpacing: 16,
  childAspectRatio: 1.5,
  children: [
    MetricTile(...),
    MetricTile(...),
  ],
)
```

### List with Cards
```dart
ListView.separated(
  padding: EdgeInsets.all(16),
  itemCount: items.length,
  separatorBuilder: (context, index) => SizedBox(height: 12),
  itemBuilder: (context, index) => IndustrialCard(...),
)
```

### Bottom Action Bar
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Theme.of(context).scaffoldBackgroundColor,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: Offset(0, -2),
      ),
    ],
  ),
  child: Row(
    children: [
      Expanded(child: OutlinedButton(...)),
      SizedBox(width: 12),
      Expanded(child: ElevatedButton(...)),
    ],
  ),
)
```

---

## Icons

### Common Icons
```dart
// Navigation
Icons.arrow_back
Icons.close
Icons.menu

// Actions
Icons.add
Icons.edit_outlined
Icons.delete_outline
Icons.search
Icons.filter_list

// Status
Icons.check_circle (success)
Icons.error_outline (error)
Icons.warning_amber (warning)
Icons.info_outline (info)

// Business
Icons.inventory_2_outlined
Icons.shopping_cart_outlined
Icons.local_shipping_outlined
Icons.work_outline
Icons.people_outline
Icons.business_outlined

// Scanning
Icons.qr_code_scanner
Icons.barcode_scanner

// Location
Icons.location_on_outlined
Icons.navigation
Icons.map_outlined

// Time
Icons.access_time
Icons.calendar_today_outlined
Icons.timer
```

---

## Responsive Breakpoints

```dart
// Mobile: < 600px
// Tablet: 600px - 1024px
// Desktop: > 1024px

// Example usage:
final isTablet = MediaQuery.of(context).size.width >= 600;
final isDesktop = MediaQuery.of(context).size.width >= 1024;
```

---

## Accessibility Guidelines

1. **Contrast Ratios**:
   - Text: Minimum 4.5:1
   - Large text (18px+): Minimum 3:1
   - Interactive elements: Minimum 3:1

2. **Touch Targets**:
   - Minimum 48x48 dp
   - Spacing between targets: 8dp minimum

3. **Text Sizing**:
   - Body text: Minimum 14px
   - Labels: Minimum 12px
   - Headings: 20px+

4. **Color Independence**:
   - Never rely on color alone
   - Use icons + text + color for status

5. **Focus Indicators**:
   - Visible focus states for keyboard navigation
   - 2px border on focused elements

---

## Dark Mode

All components automatically adapt to dark mode via:
- `Theme.of(context).brightness`
- `AppColors.textPrimaryLight` vs `AppColors.textPrimaryDark`
- `AppColors.surfaceLight` vs `AppColors.surfaceDark`

**Dark Mode Adjustments**:
- Elevated buttons use `accent` color instead of `primary`
- Input fields use `surfaceDark` background
- Cards have darker borders

---

## Animation Guidelines

### Transitions
```dart
// Page transitions: 300ms
// Button press: 150ms
// Expand/collapse: 250ms
```

### Curves
```dart
Curves.easeInOut // Default
Curves.easeOut // Enter animations
Curves.easeIn // Exit animations
```

---

## File Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_dimensions.dart
│   │   └── app_theme.dart
│   └── router/
│       └── app_router.dart
├── widgets/
│   ├── industrial_card.dart
│   ├── status_chip.dart
│   ├── metric_tile.dart
│   └── scanner_widget.dart
└── features/
    ├── dashboard/
    ├── inventory/
    ├── production/
    └── sales/
```

---

## Usage Examples

### Creating a New Screen

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';

class MyNewPage extends StatelessWidget {
  const MyNewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My New Page'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          IndustrialCard(
            child: Column(
              children: [
                Text(
                  'Hello World',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

This design system ensures **consistency**, **scalability**, and **maintainability** across the entire ERP/SCM application.
