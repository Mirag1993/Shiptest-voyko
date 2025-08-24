# Plexagon Access Management - BYOND 516 Compatibility Fix

## Overview

This patch fixes critical crashes in the Plexagon Access Management (ID Console) interface when running under BYOND 516. The main issue was `React Error #130: Cannot read property 'map' of undefined` caused by TGUI architectural changes and deprecated hooks.

## Problem Description

### Main Issues Fixed

1. **Critical Crashes**: `React Error #130` when accessing the interface
2. **Deprecated TGUI Hooks**: `useSharedState` no longer available in BYOND 516
3. **Null Reference Errors**: Backend data contained null values causing frontend crashes
4. **UI Display Issues**: Access permissions shown as buttons instead of proper list format
5. **Layout Problems**: Column overlap and visual formatting issues

### Error Examples

```
Error: Minified React error #130; visit https://reactjs.org/docs/error-decoder.html?invariant=130&args[]=undefined&args[]=
A fatal exception has occurred at 002B:C562F1B7 in TGUI. The current application will be terminated.
```

## Technical Solution

### Backend Changes (`code/modules/modular_computers/file_system/programs/card.dm`)

1. **Fixed Null Job References**:
   ```dm
   # BEFORE:
   for (var/datum/job/job in ship.job_slots)
       jobs += job.name

   # AFTER:
   for (var/datum/job/job in ship.job_slots)
       if(job && job.name)  // Check that job exists and has name
           jobs += job.name
   ```

### Frontend Changes

#### 1. AccessList Component (`tgui/packages/tgui/interfaces/common/AccessList.js`)

**Hook Compatibility Update**:
```javascript
// BEFORE:
import { useSharedState } from '../../backend';

// AFTER:
import { useLocalState } from '../../backend'; // BYOND 516 compatibility
```

**Safe State Initialization**:
```javascript
// Safe initialization to prevent undefined errors
const [selectedAccessName, setSelectedAccessName] = useLocalState(
  'accessName',
  accesses[0]?.name,
);
```

**UI Display Improvements**:
- Changed access buttons from inline display to proper table rows
- Added `fluid` property for full-width buttons
- Implemented proper tab spacing with borders and margins

**Layout Fixes**:
```javascript
// Column spacing to prevent overlaps
<Flex.Item style={{ marginRight: '10px', maxWidth: '120px' }}>
  // Left column (region tabs)
</Flex.Item>
<Flex.Item grow={1} style={{ marginLeft: '4px' }}>
  // Right column (access list)
</Flex.Item>
```

#### 2. Visual Enhancements

**Tab Styling**:
```javascript
style={{
  border: '1px solid rgba(255, 255, 255, 0.2)',
  marginBottom: '2px',
}}
```

**Compact Region Headers**:
```javascript
title={selectedAccess?.name?.[0] || '?'}  // Shows "G" for "General", etc.
```

**Access List Format**:
```javascript
<Table>
  {selectedAccessEntries.map((entry) => (
    <Table.Row key={entry.ref}>
      <Table.Cell>
        <Button
          fluid  // Full width buttons
          icon={diffIcon}
          content={entry.desc}
          color={diffColor}
          onClick={() => accessMod(entry.ref)}
        />
      </Table.Cell>
    </Table.Row>
  ))}
</Table>
```

## Installation Instructions

### Automatic Application

1. Copy the modified files to your codebase:
   - `code/modules/modular_computers/file_system/programs/card.dm`
   - `tgui/packages/tgui/interfaces/common/AccessList.js`

2. Rebuild TGUI:
   ```bash
   bin/build.cmd
   ```

3. Restart the server

### Manual Application

If you need to apply changes manually to a customized codebase:

#### Backend (DM Code)

In `card.dm`, find the job iteration loop and add null checks:
```dm
for (var/datum/job/job in ship.job_slots)
    if(job && job.name)  // Add this null check
        jobs += job.name
```

#### Frontend (TGUI)

1. **Replace useSharedState with useLocalState** in AccessList.js
2. **Add safe initialization** for selectedAccessName
3. **Implement Table structure** for access list display
4. **Add column spacing** to prevent UI overlaps

## Testing

### Test Plan

1. **Basic Functionality**:
   - Open Plexagon Access Management
   - Insert ID card
   - Authenticate with admin access
   - Switch between Access tabs

2. **Access Management**:
   - Select different regions (General, Security, Medical, etc.)
   - Grant/deny individual access permissions
   - Use "Grant All" and "Deny All" buttons
   - Test region-wide grant/deny

3. **Visual Verification**:
   - Confirm access list displays as table rows, not button tiles
   - Verify proper column spacing without overlaps
   - Check tab borders and spacing
   - Confirm single-letter region headers work correctly

4. **Error Testing**:
   - No React errors in browser console
   - No runtime errors in DM server logs
   - Stable operation during rapid tab switching

## Compatibility

- **BYOND Version**: 516.1667+
- **TGUI Version**: Compatible with Shiptest's TGUI implementation
- **Backward Compatibility**: This patch maintains full functionality while fixing BYOND 516 specific issues

## Technical Details

### Root Cause Analysis

The crashes were caused by a combination of factors:

1. **TGUI Architecture Changes**: BYOND 516 uses a newer TGUI version where `useSharedState` was deprecated
2. **Data Integrity Issues**: Backend job slots contained null references
3. **Unsafe Array Operations**: Frontend code assumed arrays would always be populated
4. **Layout Incompatibilities**: CSS and component structure changes in newer TGUI

### Performance Impact

- **Minimal Performance Impact**: Changes are primarily safety checks and display formatting
- **Memory Usage**: Unchanged
- **Network Traffic**: Unchanged
- **Render Performance**: Slightly improved due to better component structure

## Known Limitations

- Single-letter region headers may be less descriptive than full names
- Maximum left column width is capped at 120px to prevent overlaps

## Author

**Mirag1993** - Initial problem identification and comprehensive fix implementation

## Version History

- **v1.0** - Initial BYOND 516 compatibility patch
- **v1.1** - Visual improvements and layout fixes
- **v1.2** - Final cleanup and documentation

---

*This patch ensures stable operation of the Plexagon Access Management system under BYOND 516 while maintaining all original functionality and improving the user interface.*
