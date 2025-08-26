import { useBackend } from '../backend';
import {
  Button,
  Section,
  Box,
  LabeledList,
  ProgressBar,
  Table,
  Stack,
  Slider,
} from '../components';
import { Window } from '../layouts';

interface ConsoleData {
  active: boolean;
  reactor_uid?: number;
  reactor_state?: number;
  reactor_state_text?: string;
  rod_position?: number;
  temp_core?: number;
  temp_max?: number;
  flux?: number;
  power_kw?: number;
  heat_kw?: number;
  target_power?: number;
  auto_mode?: boolean;
  emergency_valve?: boolean;
  meltdown_stage?: number;
  has_fuel?: boolean;
  fuel_type?: string;
  burnup?: number;
  reactivity?: number;
  coolant_mode?: string;
  coolant_flow?: number;
  rad_emit?: number;
  has_radiator?: boolean;
  has_heat_exchanger?: boolean;
  cooling_systems?: {
    radiator: boolean;
    heat_exchanger: boolean;
  };
  gas_temperature?: number;
  gas_pressure?: number;
  gases?: Array<{
    name: string;
    amount: number;
    id: string;
  }>;
  reactors?: Array<{
    area_name: string;
    uid: number;
    state: number;
    state_text: string;
    temp_core: number;
    power_kw: number;
  }>;
}

export const CNRConsole = (props, context) => {
  const { act, data } = useBackend<ConsoleData>(context);

  if (!data.active) {
    return <ReactorList />;
  }

  return <ReactorMonitor />;
};

const ReactorList = (props, context) => {
  const { act, data } = useBackend<ConsoleData>(context);
  const { reactors = [] } = data;

  return (
    <Window width={600} height={400} resizable>
      <Window.Content scrollable>
        <Section
          title="Detected Reactors"
          buttons={
            <Button
              icon="sync"
              content="Refresh"
              onClick={() => act('PRG_refresh')}
            />
          }
        >
          <Table>
            {reactors.map((reactor) => (
              <Table.Row key={reactor.uid}>
                <Table.Cell>{reactor.uid + '. ' + reactor.area_name}</Table.Cell>
                <Table.Cell collapsing color="label">
                  Status:
                </Table.Cell>
                <Table.Cell collapsing width="120px">
                  <ProgressBar
                    value={reactor.state === 2 ? 1 : 0}
                    ranges={{
                      good: [0.5, Infinity],
                      average: [0.2, 0.5],
                      bad: [-Infinity, 0.2],
                    }}
                  >
                    {reactor.state_text}
                  </ProgressBar>
                </Table.Cell>
                <Table.Cell collapsing>
                  <Button
                    content="Connect"
                    onClick={() =>
                      act('PRG_set', {
                        target: reactor.uid,
                      })
                    }
                  />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};

const ReactorMonitor = (props, context) => {
  const { act, data } = useBackend<ConsoleData>(context);
  const {
    reactor_uid,
    reactor_state,
    reactor_state_text,
    rod_position,
    temp_core,
    temp_max,
    flux,
    power_kw,
    heat_kw,
    target_power,
    auto_mode,
    emergency_valve,
    meltdown_stage,
    has_fuel,
    fuel_type,
    burnup,
    reactivity,
    coolant_mode,
    coolant_flow,
    rad_emit,
    has_radiator,
    has_heat_exchanger,
    cooling_systems,
    gas_temperature,
    gas_pressure,
    gases,
  } = data;

  const getReactorStateColor = () => {
    if (meltdown_stage && meltdown_stage > 0) return 'bad';
    if (reactor_state === 2) return 'good';
    if (reactor_state === 1) return 'average';
    return 'grey';
  };

  return (
    <Window width={800} height={600} resizable>
      <Window.Content scrollable>
        <Stack>
          <Stack.Item width="400px">
            <Section
              title={`Reactor ${reactor_uid} - ${reactor_state_text}`}
              buttons={
                <Button
                  icon="arrow-left"
                  content="Disconnect"
                  onClick={() => act('PRG_clear')}
                />
              }
            >
              <LabeledList>
                <LabeledList.Item label="Status" color={getReactorStateColor()}>
                  {reactor_state_text?.toUpperCase()}
                </LabeledList.Item>
                
                <LabeledList.Item label="Core Temperature">
                  <ProgressBar
                    value={temp_core && temp_max ? temp_core / temp_max : 0}
                    ranges={{
                      good: [0, 0.6],
                      average: [0.6, 0.8],
                      bad: [0.8, Infinity],
                    }}
                  >
                    {temp_core?.toFixed(1)}K / {temp_max}K
                  </ProgressBar>
                </LabeledList.Item>

                <LabeledList.Item label="Power Output">
                  <ProgressBar
                    value={power_kw ? power_kw / 1000 : 0}
                    ranges={{
                      good: [0, 0.8],
                      average: [0.8, 1.0],
                      bad: [1.0, Infinity],
                    }}
                  >
                    {power_kw?.toFixed(1)} kW
                  </ProgressBar>
                </LabeledList.Item>

                <LabeledList.Item label="Heat Generation">
                  {heat_kw?.toFixed(1)} kW
                </LabeledList.Item>

                <LabeledList.Item label="Neutron Flux">
                  {flux?.toFixed(3)}
                </LabeledList.Item>

                <LabeledList.Item label="Radiation">
                  {rad_emit?.toFixed(1)} units
                </LabeledList.Item>

                <LabeledList.Item label="Fuel Status">
                  {has_fuel ? (
                    <Box>
                      <Box>Type: {fuel_type}</Box>
                      <Box>Burnup: {(burnup * 100)?.toFixed(1)}%</Box>
                      <Box>Reactivity: {reactivity?.toFixed(3)}</Box>
                    </Box>
                  ) : (
                    'No Fuel'
                  )}
                </LabeledList.Item>

                <LabeledList.Item label="Cooling Systems">
                  <Box>
                    <Box color={has_radiator ? 'green' : 'red'}>
                      Radiator: {has_radiator ? 'Connected' : 'Disconnected'}
                    </Box>
                    <Box color={has_heat_exchanger ? 'green' : 'red'}>
                      Heat Exchanger: {has_heat_exchanger ? 'Connected' : 'Disconnected'}
                    </Box>
                  </Box>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item grow={1} basis={0}>
            <Section title="Controls">
              <Stack vertical>
                <Stack.Item>
                  <Button
                    content={reactor_state === 2 ? 'Stop Reactor' : 'Start Reactor'}
                    color={reactor_state === 2 ? 'red' : 'green'}
                    onClick={() => act(reactor_state === 2 ? 'stop_reactor' : 'start_reactor')}
                  />
                  <Button
                    content="SCRAM"
                    color="red"
                    onClick={() => act('scram_reactor')}
                  />
                </Stack.Item>

                <Stack.Item>
                  <LabeledList>
                    <LabeledList.Item label="Control Rods">
                      <Slider
                        value={rod_position * 100}
                        minValue={0}
                        maxValue={100}
                        step={1}
                        stepPixelSize={2}
                        onChange={(e, value) =>
                          act('set_rod_position', {
                            position: value / 100,
                          })
                        }
                      />
                      {(rod_position * 100)?.toFixed(1)}%
                    </LabeledList.Item>

                    <LabeledList.Item label="Target Power">
                      <Slider
                        value={target_power}
                        minValue={0}
                        maxValue={1000}
                        step={10}
                        stepPixelSize={2}
                        onChange={(e, value) =>
                          act('set_target_power', {
                            power: value,
                          })
                        }
                      />
                      {target_power} kW
                    </LabeledList.Item>
                  </LabeledList>
                </Stack.Item>

                <Stack.Item>
                  <Button
                    content={auto_mode ? 'Auto Mode: ON' : 'Auto Mode: OFF'}
                    color={auto_mode ? 'green' : 'grey'}
                    onClick={() => act('toggle_auto_mode')}
                  />
                  <Button
                    content={emergency_valve ? 'Emergency Valve: OPEN' : 'Emergency Valve: CLOSED'}
                    color={emergency_valve ? 'red' : 'green'}
                    onClick={() => act('toggle_emergency_valve')}
                  />
                </Stack.Item>

                <Stack.Item>
                  <Button
                    content="Eject Fuel"
                    color="orange"
                    onClick={() => act('eject_fuel')}
                  />
                  <Button
                    content="Find Cooling"
                    color="blue"
                    onClick={() => act('find_cooling')}
                  />
                  <Button
                    content="Disconnect Cooling"
                    color="orange"
                    onClick={() => act('disconnect_cooling')}
                  />
                </Stack.Item>
              </Stack>
            </Section>

            {has_heat_exchanger && gases && (
              <Section title="Gas Circuit">
                <LabeledList>
                  <LabeledList.Item label="Gas Temperature">
                    {gas_temperature?.toFixed(1)}K
                  </LabeledList.Item>
                  <LabeledList.Item label="Gas Pressure">
                    {gas_pressure?.toFixed(1)} kPa
                  </LabeledList.Item>
                </LabeledList>
                <LabeledList>
                  {gases.map((gas) => (
                    <LabeledList.Item key={gas.name} label={gas.name}>
                      {gas.amount.toFixed(2)}%
                    </LabeledList.Item>
                  ))}
                </LabeledList>
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
