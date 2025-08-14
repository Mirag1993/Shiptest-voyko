# Compact Nuclear Reactor (CNR) Module

A comprehensive nuclear power generation system for Shiptest, providing realistic nuclear physics with proper cooling systems and safety features.

## Features

### 🚀 Core Reactor System
- **Realistic Nuclear Physics**: Temperature feedback, neutron flux calculation, fuel burnup
- **Multiple Fuel Types**: LEU (300kW), HEU (750kW), THOX (200kW) with different characteristics
- **Safety Systems**: SCRAM, meltdown progression, radiation containment
- **Power Integration**: Seamless integration with SS13 power networks

### ❄️ Cooling Systems
- **Air Cooling**: Radiators for space-based cooling (up to 250kW per radiator)
- **Loop Cooling**: Heat exchangers with gas circuits (up to 600kW per level)
- **Upgradeable**: Pump levels and radiator efficiency can be improved

### 🎮 Gameplay Features
- **Fuel Management**: Insert/eject fuel cells, monitor burnup
- **Control Systems**: Manual and automatic power regulation
- **Safety Procedures**: Emergency shutdowns, temperature monitoring
- **Radiation Hazards**: Realistic radiation emission and containment

### 🖥️ TGUI Interface
- **Real-time Monitoring**: Live graphs of power, temperature, and flux
- **Control Panels**: Rod position, power targets, safety systems
- **Alert System**: Temperature warnings, radiation alerts, meltdown notifications
- **Multi-tab Interface**: Main control, graphs, and safety monitoring

## Installation

1. **Add to mod_celadon**: Place the `compact_nuclear_reactor` folder in your `mod_celadon` directory
2. **Include in main .dme**: Add the module's .dme file to your main project
3. **Compile**: Build the project with BYOND Dream Maker

## Usage

### Basic Setup
1. **Place Reactor**: Build the compact nuclear reactor in your ship's engineering
2. **Install Cooling**: Add radiators (for space) or heat exchangers (for atmos)
3. **Insert Fuel**: Add a fuel cell to the reactor
4. **Start Up**: Use the control console to start the reactor

### Fuel Types
- **LEU (Low Enriched Uranium)**: 300kW nominal, 45 minutes runtime, stable
- **HEU (High Enriched Uranium)**: 750kW nominal, 25 minutes runtime, requires good cooling
- **THOX (Thorium Oxide)**: 200kW nominal, 75 minutes runtime, long-lasting

### Cooling Options
- **Air Cooling**: Place radiators near space for passive cooling
- **Loop Cooling**: Connect heat exchangers to gas circuits for active cooling

## Configuration

The module uses `config/cnr.json` for balance settings:
- Fuel characteristics and burn rates
- Cooling capacities and efficiencies
- Safety thresholds and meltdown parameters
- UI update intervals and alert cooldowns

## Safety Features

### Automatic Safety
- **Temperature SCRAM**: Automatic shutdown at 1200K
- **Radiation Monitoring**: Alerts at high radiation levels
- **Fuel Depletion**: Automatic shutdown when fuel is depleted

### Manual Controls
- **Emergency SCRAM**: Manual shutdown button
- **Control Rods**: Manual rod insertion/withdrawal
- **Emergency Valve**: Steam dump valve for pressure relief

### Meltdown Progression
1. **Stage 1**: Reduced cooling efficiency (70%)
2. **Stage 2**: Severe damage, radiation leakage (40% cooling)
3. **Stage 3**: Complete meltdown, radioactive debris

## Technical Details

### Physics Model
- **Neutron Flux**: Calculated from reactivity and temperature feedback
- **Heat Generation**: Based on fuel type and power output
- **Temperature Dynamics**: Realistic heat transfer and cooling
- **Fuel Burnup**: Gradual fuel depletion over time

### Power Integration
- **Power Network**: Direct integration with SS13 power systems
- **Load Balancing**: Automatic power distribution
- **Efficiency**: Realistic conversion from nuclear to electrical power

### Radiation System
- **Emission**: Based on temperature and neutron flux
- **Containment**: Automatic radiation shielding
- **Detection**: Compatible with existing radiation systems

## Compatibility

### Existing Systems
- **Power Networks**: Full compatibility with SS13 power system
- **Atmospherics**: Integration with gas circuits and heat exchange
- **Radiation**: Uses existing radiation mechanics
- **TGUI**: Standard TGUI framework integration

### Fuel Cell Compatibility
The module includes compatibility layers for existing fuel cells:
- Adds missing properties (burnup, reactivity, etc.)
- Maintains backward compatibility
- Supports existing fuel cell types

## Development

### File Structure
```
mod_celadon/compact_nuclear_reactor/
├── code/
│   ├── machinery/
│   │   ├── power/cnr.dm
│   │   ├── cooling/
│   │   │   ├── cnr_radiator.dm
│   │   │   └── cnr_heat_exchanger.dm
│   │   └── computer/cnr_console.dm
│   └── objects/items/nuclear_fuel_cell.dm
├── config/cnr.json
├── compact_nuclear_reactor.dme
└── README.md
```

### Key Components
- **Reactor Core**: Main power generation and physics simulation
- **Fuel Cells**: Different fuel types with varying characteristics
- **Cooling Systems**: Air and loop cooling options
- **Control Console**: TGUI interface for monitoring and control
- **Safety Systems**: Automatic and manual safety features

## Testing

### Test Scenarios
1. **Basic Operation**: LEU fuel with single radiator
2. **High Power**: HEU fuel with proper cooling
3. **Safety Systems**: Temperature and radiation monitoring
4. **Meltdown**: Emergency procedures and damage assessment
5. **Fuel Management**: Insertion, depletion, and replacement

### Performance
- **Processing**: Optimized for 2-second update intervals
- **Memory**: Efficient data structures and cleanup
- **Network**: Minimal power network impact
- **UI**: Responsive TGUI interface

## Contributing

### Code Standards
- Follow SS13 coding standards
- Use proper DM patterns (Initialize/Destroy, signals)
- Maintain TGUI best practices
- Include proper documentation

### Testing
- Test all fuel types and cooling configurations
- Verify safety systems and emergency procedures
- Check power network integration
- Validate TGUI functionality

## License

This module follows the same license as the main Shiptest project.

## Support

For issues and questions:
- Check the configuration file for balance settings
- Verify cooling system connections
- Test with different fuel types
- Review safety system logs

---

**Note**: This module provides realistic nuclear power generation. Always follow proper safety procedures and monitor reactor conditions carefully!
