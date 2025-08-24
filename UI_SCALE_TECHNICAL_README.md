# UI Scale System - Technical Documentation

**Author**: Mirag1993

## Overview

The UI Scale system allows players to adjust the size of game interface elements (TGUI windows and BYOND browser windows) to improve readability and usability. The system supports scaling from 0.8x to 1.2x (80% to 120% of original size).

## Architecture

The UI Scale system consists of three main components:

1. **Backend (DM)**: Player preferences storage and data transmission
2. **BYOND Browser Scaling**: Window size and content scaling for browser-based UIs
3. **TGUI Frontend Scaling**: CSS-based scaling for React-based interfaces

## Backend Implementation

### Preferences Structure

**File**: `code/modules/client/preferences.dm`

```dm
// UI Scale constants - range for user interface scaling
#define UI_SCALE_MIN 0.8
#define UI_SCALE_MAX 1.2

/datum/preferences
    var/ui_scale_enabled = FALSE  // Boolean: whether UI Scale is enabled
    var/ui_scale_value = 1.0      // Float: scale factor value (0.8-1.2)
```

### Data Transmission

**File**: `code/modules/tgui/tgui.dm`

The backend transmits UI Scale data to TGUI through the config object:

```dm
"ui_scale" = user.client?.prefs?.get_ui_scale_data()
```

The `get_ui_scale_data()` method returns:
```dm
return list(
    "enabled" = ui_scale_enabled,
    "value" = ui_scale_value,
    "min" = UI_SCALE_MIN,
    "max" = UI_SCALE_MAX
)
```

### Savefile Management

**File**: `code/modules/client/preferences_savefile.dm`

- Preferences are saved with version tracking
- Values are clamped to valid range (0.8-1.2) on load and save
- Backward compatibility maintained for older save files

## BYOND Browser Scaling

**File**: `code/datums/browser.dm`

BYOND browser windows (like admin panels, player info, etc.) are scaled through two mechanisms:

### 1. Window Size Scaling
```dm
// Apply UI Scale to window dimensions when enabled
if(user.client?.prefs?.ui_scale_enabled)
    var/scaling = user.client.prefs.ui_scale_value
    window_size = "size=[width * scaling]x[height * scaling];"
```

### 2. Content Scaling
```dm
// CSS zoom for UI Scale when enabled - scales browser window content
else if(user.client?.prefs?.ui_scale_enabled && user.client?.prefs?.ui_scale_value && user.client?.prefs.ui_scale_value != 1)
    head_content += {"
        <style>
            body {
                zoom: [user.client.prefs.ui_scale_value * 100]%;
            }
        </style>
        "}
```

This approach ensures that both the window dimensions and content scale proportionally.

## TGUI Frontend Scaling

### React Hook Implementation

**File**: `tgui/packages/tgui/hooks/useUiScale.ts`

The `useUiScale` hook applies scaling through multiple CSS mechanisms:

```typescript
// Apply UI Scale only when enabled
if (uiScale?.enabled && uiScale?.value) {
  // Set --scaling-amount for vp() functions
  document.documentElement.style.setProperty(
    '--scaling-amount',
    String(uiScale.value),
  );
  // Set --tgui-scale for content containers
  document.documentElement.style.setProperty(
    '--tgui-scale',
    String(uiScale.value),
  );
  // Apply scaling to base font size for rem-based elements
  document.documentElement.style.fontSize = `${12 * uiScale.value}px`;
}
```

### CSS Implementation

**File**: `tgui/packages/tgui/styles/ui-scale.scss`

The CSS applies `zoom` property to content containers while preserving title bar sizes:

```scss
// Apply scaling to main content containers and interactive elements
.Window__content,
.Layout__content,
.Section__content,
.Section,
.Stack,
.LabeledList,
.Table,
.Button,
.Input,
.Slider {
  zoom: var(--tgui-scale, 1);
}

// Exclude title bars from additional scaling since they are already
// scaled through font-size changes to avoid double scaling
.TitleBar,
.TitleBar__title,
.Window__titleText {
  zoom: 1 !important;
}
```

### Integration Point

**File**: `tgui/packages/tgui/App.tsx`

The hook is applied globally at the root level:

```typescript
export function App() {
  // Apply UI Scale through TGUI's built-in scaling system
  useUiScale();
  
  return <Component />;
}
```

## Scaling Methods Explained

### 1. CSS Zoom Property
- **Used for**: TGUI content containers and BYOND browser content
- **Advantages**: Scales everything proportionally (text, images, spacing)
- **Disadvantages**: None significant for this use case

### 2. Font-size Scaling
- **Used for**: rem-based elements (primarily titles)
- **Method**: Adjusts `document.documentElement.style.fontSize`
- **Base**: 12px (TGUI standard)

### 3. CSS Variables
- **`--scaling-amount`**: Used by TGUI's `vp()` function (limited usage)
- **`--tgui-scale`**: Custom variable for content containers

## User Interface

### Preferences Menu

Players can:
1. **Toggle UI Scale**: ON/OFF switch (`ui_scale_enabled`)
2. **Set Scale Value**: Input field for precise value (`ui_scale_value`)
   - Range: 0.8 to 1.2
   - Default: 1.0
   - Only visible when UI Scale is enabled

### Input Validation

All user inputs are validated and clamped:
```dm
ui_scale_value = clamp(ui_scale_value, UI_SCALE_MIN, UI_SCALE_MAX)
```

## Admin Panel Integration

**Files**: 
- `code/modules/admin/player_panel.dm`
- `code/modules/admin/view_variables/view_variables.dm`

Admin panels respect UI Scale settings and scale their windows accordingly to maintain usability for administrators with different scale preferences.

## Technical Considerations

### Performance
- CSS zoom is hardware-accelerated and performant
- No layout recalculations required
- Minimal JavaScript overhead

### Compatibility
- Works with BYOND 516+
- Compatible with all browsers used by TGUI
- Backward compatible with older save files

### Limitations
- Scale range limited to 0.8-1.2 to prevent usability issues
- Some pixel-perfect layouts may show minor artifacts at extreme scales
- Title bars intentionally excluded from content scaling to maintain window aesthetics

## Testing

### Test Cases
1. **Default State**: New players have UI Scale OFF, value 1.0
2. **Range Validation**: Values outside 0.8-1.2 are clamped
3. **Save/Load**: Settings persist across sessions
4. **BYOND Windows**: Browser windows scale correctly
5. **TGUI Windows**: Interface elements scale proportionally
6. **Title Preservation**: Window titles maintain appropriate size

### Manual Testing
1. Create new character → verify defaults
2. Enable UI Scale, set to 0.8 → verify smaller interface
3. Set to 1.2 → verify larger interface
4. Disable UI Scale → verify return to normal size
5. Restart game → verify settings persistence

## Debugging

### Common Issues
1. **Text still large when disabled**: Check `document.documentElement.style.fontSize` is reset to 12px
2. **BYOND windows not scaling**: Verify `ui_scale_enabled` and `ui_scale_value` are correctly read
3. **Title bars wrong size**: Ensure `zoom: 1 !important` is applied to title elements

### Debug Tools
- Browser DevTools: Check CSS variables and computed styles
- DM compiler: Verify no undefined variables
- TGUI console: Check for JavaScript errors

## Future Improvements

### Potential Enhancements
1. **Panel-specific scaling**: Different scales for different interface types
2. **Accessibility integration**: Integration with system accessibility settings
3. **Dynamic range**: Adjustable min/max values based on screen resolution
4. **Smooth transitions**: CSS transitions for scale changes

### Code Maintenance
- Keep CSS selectors up to date with TGUI component changes
- Monitor performance impact of additional scaled elements
- Regular testing across different browsers and screen sizes

---

## File Modification Summary

### Modified Files
- `code/modules/client/preferences.dm` - Backend preferences and UI
- `code/modules/client/preferences_savefile.dm` - Save/load logic
- `code/modules/tgui/tgui.dm` - Data transmission to frontend
- `code/datums/browser.dm` - BYOND window scaling
- `code/modules/admin/player_panel.dm` - Admin panel scaling
- `code/modules/admin/view_variables/view_variables.dm` - View variables scaling
- `tgui/packages/tgui/App.tsx` - React hook integration
- `tgui/packages/tgui/hooks/useUiScale.ts` - Scaling logic
- `tgui/packages/tgui/styles/main.scss` - CSS import
- `tgui/packages/tgui/styles/ui-scale.scss` - Scaling styles

### Added Files
- `tgui/packages/tgui/hooks/useUiScale.ts` - React hook for scaling
- `tgui/packages/tgui/styles/ui-scale.scss` - CSS scaling rules

This implementation provides a robust, user-friendly UI scaling system that respects player preferences while maintaining interface integrity and performance.
