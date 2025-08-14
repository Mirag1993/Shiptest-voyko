import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Chart,
  ColorBox,
  Flex,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
  Tabs,
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
  process_log: ProcessLogEntry[];
}

interface ProcessLogEntry {
  time: number;
  power: number;
  temp: number;
  flux: number;
  rad: number;
  state: number;
}

const REAC_OFF = 0;
const REAC_STARTING = 1;
const REAC_RUNNING = 2;
const REAC_SCRAM = 3;
const REAC_MELTDOWN = 4;

export const CompactNuclearReactor = (props, context) => {
  const { data, act } = useBackend<ReactorData>(context);
  const [activeTab, setActiveTab] = useLocalState(context, 'activeTab', 'main');

  const getStateColor = (state: number) => {
    switch (state) {
      case REAC_OFF:
        return 'grey';
      case REAC_STARTING:
        return 'yellow';
      case REAC_RUNNING:
        return 'green';
      case REAC_SCRAM:
        return 'red';
      case REAC_MELTDOWN:
        return 'purple';
      default:
        return 'grey';
    }
  };

  const getTemperatureColor = (temp: number, max: number) => {
    const ratio = temp / max;
    if (ratio < 0.5) return 'green';
    if (ratio < 0.75) return 'yellow';
    if (ratio < 0.9) return 'orange';
    return 'red';
  };

  const getRadiationColor = (rad: number) => {
    if (rad < 10) return 'green';
    if (rad < 30) return 'yellow';
    if (rad < 50) return 'orange';
    return 'red';
  };

  const processLogToChartData = (log: ProcessLogEntry[]) => {
    return log.map((entry, index) => ({
      x: index,
      y: entry.power,
    }));
  };

  const tempLogToChartData = (log: ProcessLogEntry[]) => {
    return log.map((entry, index) => ({
      x: index,
      y: entry.temp,
    }));
  };

  return (
    <Window width={800} height={600} title="Compact Nuclear Reactor Control">
      <Window.Content>
        <Stack fill>
          <Stack.Item width="200px">
            <Section title="Status">
              <LabeledList>
                <LabeledList.Item label="State">
                  <ColorBox color={getStateColor(data.state)} />
                  {data.state_text}
                </LabeledList.Item>
                <LabeledList.Item label="Temperature">
                  <ColorBox
                    color={getTemperatureColor(data.temp_core, data.temp_max)}
                  />
                  {data.temp_core}K / {data.t_max}K
                </LabeledList.Item>
                <LabeledList.Item label="Power Output">
                  {data.power_kw} kW
                </LabeledList.Item>
                <LabeledList.Item label="Heat Generation">
                  {data.heat_kw} kW
                </LabeledList.Item>
                <LabeledList.Item label="Neutron Flux">
                  {data.flux.toFixed(3)}
                </LabeledList.Item>
                <LabeledList.Item label="Radiation">
                  <ColorBox color={getRadiationColor(data.rad_emit)} />
                  {data.rad_emit.toFixed(1)} units
                </LabeledList.Item>
                <LabeledList.Item label="Coolant Flow">
                  {data.coolant_flow.toFixed(1)} kg/s
                </LabeledList.Item>
                <LabeledList.Item label="Coolant Mode">
                  {data.coolant_mode.toUpperCase()}
                </LabeledList.Item>
              </LabeledList>
            </Section>

            <Section title="Fuel Cell">
              {data.has_fuel ? (
                <LabeledList>
                  <LabeledList.Item label="Type">
                    {data.fuel_type}
                  </LabeledList.Item>
                  <LabeledList.Item label="Burnup">
                    <ProgressBar
                      value={data.burnup}
                      maxValue={1}
                      color={data.burnup > 0.2 ? 'green' : 'red'}
                    >
                      {Math.round(data.burnup * 100)}%
                    </ProgressBar>
                  </LabeledList.Item>
                  <LabeledList.Item label="Reactivity">
                    {data.reactivity?.toFixed(3)}
                  </LabeledList.Item>
                </LabeledList>
              ) : (
                <Box color="red">No fuel cell installed</Box>
              )}
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Tabs>
              <Tabs.Tab
                selected={activeTab === 'main'}
                onClick={() => setActiveTab('main')}
              >
                Main Control
              </Tabs.Tab>
              <Tabs.Tab
                selected={activeTab === 'graphs'}
                onClick={() => setActiveTab('graphs')}
              >
                Graphs
              </Tabs.Tab>
              <Tabs.Tab
                selected={activeTab === 'safety'}
                onClick={() => setActiveTab('safety')}
              >
                Safety
              </Tabs.Tab>
            </Tabs>

            {activeTab === 'main' && (
              <Section title="Reactor Control">
                <Flex>
                  <Flex.Item grow>
                    <Section title="Control Rods">
                      <LabeledList>
                        <LabeledList.Item label="Position">
                          <ProgressBar
                            value={1 - data.rod_frac}
                            maxValue={1}
                            color="blue"
                          >
                            {Math.round((1 - data.rod_frac) * 100)}%
                          </ProgressBar>
                        </LabeledList.Item>
                      </LabeledList>
                      <Button
                        fluid
                        onClick={() => act('set_rod_frac', { value: 0 })}
                        disabled={data.state === REAC_SCRAM}
                      >
                        Withdraw All
                      </Button>
                      <Button
                        fluid
                        onClick={() => act('set_rod_frac', { value: 1 })}
                      >
                        Insert All
                      </Button>
                    </Section>
                  </Flex.Item>

                  <Flex.Item grow>
                    <Section title="Power Control">
                      <LabeledList>
                        <LabeledList.Item label="Target Power">
                          <Button
                            onClick={() =>
                              act('set_target_power', {
                                value: data.target_power - 50,
                              })
                            }
                            disabled={data.target_power <= 0}
                          >
                            -
                          </Button>
                          {data.target_power} kW
                          <Button
                            onClick={() =>
                              act('set_target_power', {
                                value: data.target_power + 50,
                              })
                            }
                          >
                            +
                          </Button>
                        </LabeledList.Item>
                        <LabeledList.Item label="Auto Mode">
                          <Button
                            onClick={() => act('toggle_auto_mode')}
                            color={data.auto_mode ? 'green' : 'red'}
                          >
                            {data.auto_mode ? 'ON' : 'OFF'}
                          </Button>
                        </LabeledList.Item>
                      </LabeledList>
                    </Section>
                  </Flex.Item>
                </Flex>

                <Section title="Reactor Operations">
                  <Flex>
                    <Flex.Item grow>
                      <Button
                        fluid
                        color="green"
                        onClick={() => act('start_reactor')}
                        disabled={data.state !== REAC_OFF || !data.has_fuel}
                      >
                        Start Reactor
                      </Button>
                    </Flex.Item>
                    <Flex.Item grow>
                      <Button
                        fluid
                        color="red"
                        onClick={() => act('scram_reactor')}
                        disabled={data.state === REAC_OFF}
                      >
                        SCRAM
                      </Button>
                    </Flex.Item>
                  </Flex>
                  <Button
                    fluid
                    color="orange"
                    onClick={() => act('eject_fuel')}
                    disabled={
                      data.state === REAC_RUNNING || data.temp_core > 350
                    }
                  >
                    Eject Fuel Cell
                  </Button>
                </Section>
              </Section>
            )}

            {activeTab === 'graphs' && (
              <Section title="Real-time Monitoring">
                <Flex>
                  <Flex.Item grow>
                    <Section title="Power Output">
                      <Chart.Line
                        data={processLogToChartData(data.process_log)}
                        height={150}
                        color="green"
                      />
                    </Section>
                  </Flex.Item>
                  <Flex.Item grow>
                    <Section title="Temperature">
                      <Chart.Line
                        data={tempLogToChartData(data.process_log)}
                        height={150}
                        color="red"
                      />
                    </Section>
                  </Flex.Item>
                </Flex>
              </Section>
            )}

            {activeTab === 'safety' && (
              <Section title="Safety Systems">
                <LabeledList>
                  <LabeledList.Item label="Meltdown Stage">
                    {data.meltdown_stage > 0 ? (
                      <Box color="red">Stage {data.meltdown_stage}</Box>
                    ) : (
                      <Box color="green">Normal</Box>
                    )}
                  </LabeledList.Item>
                  <LabeledList.Item label="Emergency Valve">
                    <Button
                      onClick={() => act('toggle_emergency_valve')}
                      color={data.emergency_valve ? 'red' : 'green'}
                    >
                      {data.emergency_valve ? 'OPEN' : 'CLOSED'}
                    </Button>
                  </LabeledList.Item>
                </LabeledList>

                <Section title="Safety Alerts">
                  {data.temp_core > 900 && (
                    <Box color="orange">High Temperature Warning</Box>
                  )}
                  {data.rad_emit > 50 && (
                    <Box color="red">High Radiation Alert</Box>
                  )}
                  {data.meltdown_stage > 0 && (
                    <Box color="purple">MELTDOWN IN PROGRESS</Box>
                  )}
                  {data.has_fuel && data.burnup && data.burnup < 0.2 && (
                    <Box color="yellow">Fuel Cell Nearly Depleted</Box>
                  )}
                </Section>
              </Section>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
