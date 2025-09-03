import { useEffect } from 'react';
import {
  Box,
  Button,
  LabeledList,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

import { useBackend, useSharedState } from '../../backend';
import { Window } from '../../layouts';
import { CargoCatalog } from '../OutpostCommunicationsFaction/components/CargoCatalog';
import { Data } from '../OutpostCommunicationsFaction/types';

// Единый интерфейс для всех фракций
export const OutpostCommunicationsFactionUnified = (props, context) => {
  const { act, data } = useBackend<Data>();
  const { outpostDocked, onShip, points, faction_theme, faction_name } = data;

  const [tab, setTab] = useSharedState(context, 'outpostTab');

  // Устанавливаем вкладку cargo по умолчанию
  useEffect(() => {
    if (!tab) {
      act('debug_log', {
        message: `[DEBUG] OutpostCommunicationsFactionUnified: устанавливаем tab = 'cargo'`,
        source: 'OutpostCommunicationsFactionUnified.tsx',
        line: 'useEffect tab init',
      });
      setTab('cargo');
    }
  }, [tab, setTab]);

  return (
    <Window theme={faction_theme} width={600} height={700}>
      <Window.Content scrollable>
        <Section
          title={Math.round(points) + ' credits'}
          buttons={
            <Stack textAlign="center">
              <Stack.Item>
                <Tabs>
                  <Tabs.Tab
                    selected={tab === 'cargo'}
                    onClick={() => setTab('cargo')}
                  >
                    Cargo
                  </Tabs.Tab>
                </Tabs>
              </Stack.Item>
              <Stack.Item>
                <Button.Input
                  content="Withdraw Cash"
                  currentValue="100"
                  defaultValue="100"
                  onCommit={(e, value) =>
                    act('withdrawCash', {
                      value: value,
                    })
                  }
                />
              </Stack.Item>
            </Stack>
          }
        />
        {tab === 'cargo' && <CargoExpressContent />}
      </Window.Content>
    </Window>
  );
};

const CargoExpressContent = (props, context) => {
  const { act, data } = useBackend<Data>();
  const {
    beaconZone,
    beaconName,
    hasBeacon,
    usingBeacon,
    printMsg,
    canBuyBeacon,
    message,
  } = data;
  return (
    <>
      <Section title="Cargo Express">
        <LabeledList>
          <LabeledList.Item label="Landing Location">
            <Button
              content="Cargo Bay"
              selected={!usingBeacon}
              onClick={() => act('LZCargo')}
            />
          </LabeledList.Item>
          <LabeledList.Item label="Notice">{message}</LabeledList.Item>
        </LabeledList>
      </Section>
      <CargoCatalog />
    </>
  );
};

const ShipMissionsContent = (props, context) => {
  const { data } = useBackend<Data>();
  const { numMissions, maxMissions, outpostDocked, shipMissions } = data;
  return (
    <Section title={'Current Missions ' + numMissions + '/' + maxMissions}>
      <MissionsList showButton={outpostDocked} missions={shipMissions} />
    </Section>
  );
};

const OutpostMissionsContent = (props, context) => {
  const { data } = useBackend<Data>();
  const { numMissions, maxMissions, outpostDocked, outpostMissions } = data;
  return (
    <Section title={'Available Missions ' + numMissions + '/' + maxMissions}>
      <MissionsList showButton={outpostDocked} missions={outpostMissions} />
    </Section>
  );
};

const MissionsList = (props, context) => {
  const { showButton, missions } = props;
  const { act } = useBackend();

  if (!missions || missions.length === 0) {
    return <Box color="label">No missions available.</Box>;
  }

  return (
    <Stack vertical>
      {missions.map((mission) => (
        <Stack.Item key={mission.ref}>
          <Section
            title={mission.name}
            buttons={
              showButton && (
                <Button
                  content={mission.actStr}
                  onClick={() =>
                    act('mission-act', {
                      ref: mission.ref,
                    })
                  }
                />
              )
            }
          >
            <LabeledList>
              <LabeledList.Item label="Description">
                {mission.desc}
              </LabeledList.Item>
              <LabeledList.Item label="Progress">
                {mission.progressStr}
              </LabeledList.Item>
              <LabeledList.Item label="Value">
                {mission.value} credits
              </LabeledList.Item>
              <LabeledList.Item label="Time Remaining">
                {mission.timeStr}
              </LabeledList.Item>
            </LabeledList>
          </Section>
        </Stack.Item>
      ))}
    </Stack>
  );
};
