import { useBackend, useLocalState } from '../backend';
import {
  Button,
  Section,
  Box,
  LabeledList,
  ProgressBar,
  NoticeBox,
} from '../components';
import { Window } from '../layouts';

interface ReactorData {
  state: number;
  state_text: string;
  rod_frac: number;
  temp_core: number;
  temp_max: number;
  flux: number;
  power_kw: number;
  heat_kw: number;
  coolant_mode: string;
  coolant_flow: number;
  rad_emit: number;
  target_power: number;
  auto_mode: boolean;
  emergency_valve: boolean;
  meltdown_stage: number;
  has_fuel: boolean;
  fuel_type?: string;
  burnup?: number;
  reactivity?: number;
  has_radiator: boolean;
  has_heat_exchanger: boolean;
  cooling_systems: {
    radiator: boolean;
    heat_exchanger: boolean;
  };
}

export const CompactNuclearReactor = (props, context) => {
  const { act, data } = useBackend<ReactorData>(context);
  const [activeTab, setActiveTab] = useLocalState(context, 'activeTab', 'main');

  const {
    state,
    state_text,
    rod_frac,
    temp_core,
    temp_max,
    flux,
    power_kw,
    heat_kw,
    coolant_mode,
    coolant_flow,
    rad_emit,
    target_power,
    auto_mode,
    emergency_valve,
    meltdown_stage,
    has_fuel,
    fuel_type,
    burnup,
    reactivity,
    has_radiator,
    has_heat_exchanger,
    cooling_systems,
  } = data;

  const getStateColor = () => {
    switch (state) {
      case 0:
        return 'grey'; // OFF
      case 1:
        return 'yellow'; // STARTING
      case 2:
        return 'green'; // RUNNING
      case 3:
        return 'orange'; // SCRAM
      case 4:
        return 'red'; // MELTDOWN
      default:
        return 'grey';
    }
  };

  const getTempColor = () => {
    if (temp_core > temp_max * 0.9) return 'red';
    if (temp_core > temp_max * 0.7) return 'orange';
    if (temp_core > temp_max * 0.5) return 'yellow';
    return 'green';
  };

  return (
    <Window width={600} height={500}>
      <Window.Content>
        <Section title="Compact Nuclear Reactor Control">
          <Box>
            <LabeledList>
              <LabeledList.Item label="Status" color={getStateColor()}>
                {state_text}
              </LabeledList.Item>

              <LabeledList.Item label="Temperature" color={getTempColor()}>
                {temp_core}K / {temp_max}K
                <ProgressBar
                  value={temp_core / temp_max}
                  color={getTempColor()}
                  mt={1}
                />
              </LabeledList.Item>

              <LabeledList.Item label="Power Output">
                {power_kw} kW
                <ProgressBar value={power_kw / 1000} color="blue" mt={1} />
              </LabeledList.Item>

              <LabeledList.Item label="Heat Generation">
                {heat_kw} kW
              </LabeledList.Item>

              <LabeledList.Item label="Neutron Flux">
                {flux.toFixed(3)}
              </LabeledList.Item>

              <LabeledList.Item label="Control Rods">
                {(rod_frac * 100).toFixed(1)}% inserted
                <ProgressBar value={rod_frac} color="purple" mt={1} />
              </LabeledList.Item>

              <LabeledList.Item label="Coolant Mode">
                {coolant_mode}
              </LabeledList.Item>

              <LabeledList.Item label="Coolant Flow">
                {coolant_flow.toFixed(1)} kg/s
              </LabeledList.Item>

              <LabeledList.Item label="Radiation">
                {rad_emit.toFixed(1)} units
              </LabeledList.Item>

              <LabeledList.Item label="Cooling Systems">
                <Box>
                  <Box color={has_radiator ? 'green' : 'red'}>
                    Radiator: {has_radiator ? 'Connected' : 'Disconnected'}
                  </Box>
                  <Box color={has_heat_exchanger ? 'green' : 'red'}>
                    Heat Exchanger:{' '}
                    {has_heat_exchanger ? 'Connected' : 'Disconnected'}
                  </Box>
                </Box>
              </LabeledList.Item>
            </LabeledList>
          </Box>

          {has_fuel && (
            <Section title="Fuel Cell Information" mt={2}>
              <LabeledList>
                <LabeledList.Item label="Fuel Type">
                  {fuel_type}
                </LabeledList.Item>
                <LabeledList.Item label="Burnup">
                  {(burnup * 100).toFixed(1)}% remaining
                  <ProgressBar value={burnup} color="green" mt={1} />
                </LabeledList.Item>
                <LabeledList.Item label="Reactivity">
                  {reactivity?.toFixed(3)}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          )}

          {meltdown_stage > 0 && (
            <NoticeBox danger mt={2}>
              MELTDOWN STAGE {meltdown_stage} - IMMEDIATE ACTION REQUIRED!
            </NoticeBox>
          )}

          <Section title="Controls" mt={2}>
            <Box>
              <Button
                content={state === 0 ? 'Start Reactor' : 'SCRAM Reactor'}
                color={state === 0 ? 'green' : 'red'}
                onClick={() =>
                  act(state === 0 ? 'start_reactor' : 'scram_reactor')
                }
                disabled={!has_fuel && state === 0}
              />

              <Button
                content="Eject Fuel"
                color="orange"
                onClick={() => act('eject_fuel')}
                disabled={state === 2} // Can't eject while running
              />

              <Button
                content={auto_mode ? 'Auto Mode: ON' : 'Auto Mode: OFF'}
                color={auto_mode ? 'green' : 'grey'}
                onClick={() => act('toggle_auto_mode')}
              />

              <Button
                content={
                  emergency_valve
                    ? 'Emergency Valve: OPEN'
                    : 'Emergency Valve: CLOSED'
                }
                color={emergency_valve ? 'red' : 'green'}
                onClick={() => act('toggle_emergency_valve')}
              />

              <Button
                content="Find Cooling Systems"
                color="blue"
                onClick={() => act('find_cooling')}
              />

              <Button
                content="Disconnect Cooling"
                color="orange"
                onClick={() => act('disconnect_cooling')}
              />
            </Box>
          </Section>
        </Section>
      </Window.Content>
    </Window>
  );
};
