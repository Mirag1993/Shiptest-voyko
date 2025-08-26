# Compact Thermogel Reactor - Icons Technical Specification
## [CELADON-ADD] CELADON_FIXES

Technical specification for missing icons required by the Compact Thermogel Reactor module.

---

## 📊 Current Icon Analysis

### ✅ Existing Icons
| File | Path | Status | Usage |
|------|------|--------|-------|
| `cnr.dmi` | `icons/machinery/cnr.dmi` | ✅ Present | Reactor core, coolers |
| `radiator.dmi` | `icons/machinery/radiator.dmi` | ✅ Present | Legacy radiator |
| `heat_exchanger.dmi` | `icons/machinery/heat_exchanger.dmi` | ✅ Present | Legacy heat exchanger |
| `fuel_cell.dmi` | `icons/objects/fuel_cell.dmi` | ✅ Present | Legacy fuel system |
| `lefthand.dmi` | `icons/mob/inhands/lefthand.dmi` | ✅ Present | In-hand sprites |
| `righthand.dmi` | `icons/mob/inhands/righthand.dmi` | ✅ Present | In-hand sprites |

### ❌ Missing Icons (Required)
| File | Path | Status | Priority | Usage |
|------|------|--------|----------|-------|
| `pipes.dmi` | `icons/machinery/pipes.dmi` | ❌ Missing | **HIGH** | Gel pipes (horizontal/vertical) |
| `gel_cell.dmi` | `icons/objects/gel_cell.dmi` | ❌ Missing | **HIGH** | Gel storage canisters |
| `modules.dmi` | `icons/objects/modules.dmi` | ❌ Missing | **MEDIUM** | Reactor modules |
| `pump.dmi` | `icons/machinery/pump.dmi` | ❌ Missing | **MEDIUM** | Gel circulation pump |

---

## 🎨 Icon Specifications

### 1. **pipes.dmi** - Gel Network Pipes
**Path**: `icons/machinery/pipes.dmi`  
**Priority**: HIGH  
**Size**: 32×32 pixels  
**Format**: DMI with transparency  

#### Required Icon States:
```
pipe_h              # Horizontal gel pipe (normal)
pipe_h_flowing      # Horizontal gel pipe (with flow)
pipe_h_hot          # Horizontal gel pipe (hot temperature)
pipe_h_cold         # Horizontal gel pipe (cold temperature)
pipe_v              # Vertical gel pipe (normal)
pipe_v_flowing      # Vertical gel pipe (with flow)
pipe_v_hot          # Vertical gel pipe (hot temperature)
pipe_v_cold         # Vertical gel pipe (cold temperature)
```

#### Design Requirements:
- **Style**: Industrial, hexagonal ports for NET_GEL compatibility
- **Colors**: Blue theme (indicating gel network)
- **Flow Effect**: Animated or static flow indicators
- **Temperature Indicators**: Color-coded (red=hot, blue=cold)
- **Compatibility**: Must be visually distinct from atmospheric pipes

### 2. **gel_cell.dmi** - Gel Storage Canisters
**Path**: `icons/objects/gel_cell.dmi`  
**Priority**: HIGH  
**Size**: 32×32 pixels  
**Format**: DMI with transparency  

#### Required Icon States:
```
gel_cell            # Standard gel cell (empty)
gel_cell_low        # Gel cell (low fill)
gel_cell_medium     # Gel cell (medium fill)
gel_cell_full       # Gel cell (full)
gel_cell_large      # Large gel cell (250L)
gel_cell_empty      # Empty gel cell
```

#### Design Requirements:
- **Style**: Pressurized canister with hexagonal ports
- **Colors**: Blue canister with gel level indicators
- **Fill Levels**: Visual fill indicators (transparent to opaque blue)
- **Size Variants**: Standard (100L) and large (250L) versions
- **Ports**: Blue hexagonal connectors for NET_GEL compatibility

### 3. **modules.dmi** - Reactor Modules
**Path**: `icons/objects/modules.dmi`  
**Priority**: MEDIUM  
**Size**: 32×32 pixels  
**Format**: DMI with transparency  

#### Required Icon States:
```
module_base         # Base module template
module_coolant_booster    # Coolant booster module
module_finned_plates      # Finned plates module
module_radiation_baffle   # Radiation baffle module
module_fuel_moderator     # Fuel moderator module
module_output_amplifier   # Output amplifier module
module_stability_liner    # Stability liner module
```

#### Design Requirements:
- **Style**: Electronic circuit board with cooling/power components
- **Colors**: Green PCB with colored components
- **Cooling Modules**: Blue/cyan theme (cooling focus)
- **Power Modules**: Red/orange theme (power focus)
- **Components**: Visible heat sinks, capacitors, cooling fins
- **Size**: Compact, fits in 2×3 grid slots

### 4. **pump.dmi** - Gel Circulation Pump
**Path**: `icons/machinery/pump.dmi`  
**Priority**: MEDIUM  
**Size**: 32×32 pixels  
**Format**: DMI with transparency  

#### Required Icon States:
```
pump                # Standard pump (inactive)
pump_active         # Standard pump (active)
pump_high           # High power pump
pump_medium         # Medium power pump
pump_low            # Low power pump
pump_advanced       # Advanced pump variant
pump_heavy          # Heavy-duty pump variant
```

#### Design Requirements:
- **Style**: Industrial pump with motor housing
- **Colors**: Steel gray with blue gel indicators
- **Power Levels**: Visual indicators for pump power
- **Active State**: Rotating or glowing elements
- **Variants**: Standard, advanced, and heavy-duty versions
- **Ports**: Blue hexagonal connectors for NET_GEL

---

## 🎯 Design Guidelines

### Color Scheme
- **Primary Blue**: `#0066CC` (NET_GEL network identification)
- **Secondary Blue**: `#0099FF` (gel flow indicators)
- **Warning Red**: `#FF3300` (high temperature)
- **Cool Blue**: `#00CCFF` (low temperature)
- **Industrial Gray**: `#666666` (machinery housing)

### Style Consistency
- **Hexagonal Ports**: All NET_GEL components must have hexagonal connectors
- **Industrial Design**: Clean, functional, engineering aesthetic
- **Size Consistency**: All icons must be 32×32 pixels
- **Transparency**: Use alpha channel for proper layering

### Technical Requirements
- **DMI Format**: BYOND-compatible DMI files
- **Transparency**: Alpha channel support for overlays
- **Animation**: Static icons (no animated DMI)
- **Compatibility**: Must work with SS13/Shiptest icon system

---

## 📋 Implementation Priority

### Phase 1 (Critical - Required for Basic Functionality)
1. **pipes.dmi** - Gel network infrastructure
2. **gel_cell.dmi** - Gel storage system

### Phase 2 (Important - Enhanced Functionality)
3. **pump.dmi** - Flow enhancement system
4. **modules.dmi** - Module customization system

---

## 🔧 Integration Requirements

### Code References
The following code files reference these icons:

```dm
// Gel pipes
/obj/machinery/cnr_pipe_h
    icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/pipes.dmi'

/obj/machinery/cnr_pipe_v
    icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/pipes.dmi'

// Gel cells
/obj/item/cnr_gel_cell
    icon = 'mod_celadon/compact_nuclear_reactor/icons/objects/gel_cell.dmi'

// Modules
/obj/item/cnr_module
    icon = 'mod_celadon/compact_nuclear_reactor/icons/objects/modules.dmi'

// Pumps
/obj/machinery/cnr_pump
    icon = 'mod_celadon/compact_nuclear_reactor/icons/machinery/pump.dmi'
```

### Icon State Mapping
```dm
// Pipe states based on flow and temperature
icon_state = "pipe_h"           // Normal horizontal
icon_state = "pipe_h_flowing"   // Flow active
icon_state = "pipe_h_hot"       // High temperature
icon_state = "pipe_h_cold"      // Low temperature

// Gel cell states based on fill level
icon_state = "gel_cell_empty"   // Empty
icon_state = "gel_cell_low"     // <40% fill
icon_state = "gel_cell_medium"  // 40-80% fill
icon_state = "gel_cell_full"    // >80% fill

// Module states based on type
icon_state = "module_coolant_booster"    // Cooling module
icon_state = "module_output_amplifier"   // Power module

// Pump states based on power and activity
icon_state = "pump"             // Inactive
icon_state = "pump_active"      // Active
icon_state = "pump_high"        // High power
```

---

## 🎨 Visual Style Guide

### NET_GEL Network Theme
- **Color**: Blue (#0066CC) for all NET_GEL components
- **Shape**: Hexagonal ports and connectors
- **Style**: Clean, industrial, engineering-focused
- **Distinction**: Must be visually different from atmospheric pipes

### Temperature Indicators
- **Normal**: Blue (#0066CC)
- **Hot**: Red (#FF3300) with heat distortion effects
- **Cold**: Light blue (#00CCFF) with frost effects

### Flow Indicators
- **Static**: Solid blue lines or arrows
- **Dynamic**: Glowing or pulsing effects
- **Direction**: Clear flow direction indicators

---

## ✅ Quality Assurance

### Testing Requirements
1. **Visual Clarity**: Icons must be clear at 32×32 resolution
2. **Color Distinction**: NET_GEL components must be distinct from atmospheric
3. **State Recognition**: Different states must be easily distinguishable
4. **Integration**: Icons must work with existing SS13 icon system

### Acceptance Criteria
- [ ] All required icon states implemented
- [ ] Consistent 32×32 pixel size
- [ ] Proper DMI format with transparency
- [ ] Visual distinction from atmospheric components
- [ ] Clear state indicators (flow, temperature, fill)
- [ ] Industrial engineering aesthetic
- [ ] Blue NET_GEL color scheme maintained

---

**Status**: Ready for Implementation  
**Priority**: High (Critical for module functionality)  
**Dependencies**: None (standalone icon requirements)
