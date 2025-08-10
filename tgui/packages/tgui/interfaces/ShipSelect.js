import { useBackend, useLocalState } from '../backend';
import {
  Button,
  Section,
  Tabs,
  Table,
  LabeledList,
  Collapsible,
  Flex,
  Box,
} from '../components';
import { Window } from '../layouts';
import { createSearch, decodeHtmlEntities } from 'common/string';
import { logger } from '../logging';
import { FactionButtons } from './FactionButtons';
import { ShipBrowser } from './ShipBrowser';

// Цвета фракций для стилизации
const FACTION_COLORS = {
  'nanotrasen': { bg: '#283674', text: 'white' },
  'syndicate': { bg: '#000000', text: '#B22C20' },
  'inteq': { bg: '#7E6641', text: '#FFD700' },
  'inteq risk management group': { bg: '#7E6641', text: '#FFD700' },
  'solfed': { bg: '#FFFFFF', text: '#000080' },
  'independent': { bg: '#283674', text: '#FFD700' },
  'elysium': { bg: '#228B22', text: 'white' },
  'pirates': { bg: '#000000', text: 'white' },
  'other': { bg: '#000080', text: 'white' },
};

// Функция для получения цвета фракции
const getFactionColor = (factionName) => {
  if (!factionName) return { bg: '#666', text: 'white' };

  const factionLower = String(factionName).toLowerCase();

  // Проверяем точные совпадения
  if (FACTION_COLORS[factionLower]) {
    return FACTION_COLORS[factionLower];
  }

  // Проверяем частичные совпадения
  if (factionLower.includes('nanotrasen') || factionLower.includes('nt')) {
    return FACTION_COLORS.nanotrasen;
  }
  if (factionLower.includes('syndicate') || factionLower.includes('syn')) {
    return FACTION_COLORS.syndicate;
  }
  if (
    factionLower.includes('inteq') ||
    factionLower.includes('inteq risk management group')
  ) {
    return FACTION_COLORS.inteq;
  }
  if (factionLower.includes('solfed') || factionLower.includes('sf')) {
    return FACTION_COLORS.solfed;
  }
  if (factionLower.includes('independent') || factionLower.includes('ind')) {
    return FACTION_COLORS.independent;
  }
  if (factionLower.includes('elysium')) {
    return FACTION_COLORS.elysium;
  }
  if (factionLower.includes('pirates') || factionLower.includes('pirate')) {
    return FACTION_COLORS.pirates;
  }

  return FACTION_COLORS.other;
};

const findShipByRef = (ship_list, ship_ref) => {
  for (let i = 0; i < ship_list.length; i++) {
    if (ship_list[i].ref === ship_ref) return ship_list[i];
  }
  return null;
};

export const ShipSelect = (props, context) => {
  const { act, data } = useBackend(context);

  // Используем ui_static_data для ships и templates
  const ships = data.ships || [];
  const templates = data.templates || [];

  const [currentTab, setCurrentTab] = useLocalState(context, 'tab', 1);

  // Убираем всю логику переключения вкладок - DM код сам управляет интерфейсом

  const [selectedShipRef, setSelectedShipRef] = useLocalState(
    context,
    'selectedShipRef',
    null
  );

  const selectedShip = findShipByRef(ships, selectedShipRef);

  const applyStates = {
    open: 'Open',
    apply: 'Apply',
    closed: 'Locked',
  };
  const [shownTabs, setShownTabs] = useLocalState(context, 'tabs', [
    { name: 'Ship Select', tab: 1 },
    { name: 'Ship Purchase', tab: 3 },
  ]);
  const searchFor = (searchText) =>
    createSearch(searchText, (thing) => thing.name);

  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');

  return (
    <Window title="Ship Select" width={860} height={640} resizable>
      <Window.Content scrollable>
        <Tabs style={{ display: 'flex', width: '100%' }}>
          {shownTabs.map((tabbing, index) => (
            <Tabs.Tab
              key={`${index}-${tabbing.name}`}
              selected={currentTab === tabbing.tab}
              onClick={() => setCurrentTab(tabbing.tab)}
              style={{ flex: 1, textAlign: 'center' }}
            >
              {tabbing.name}
            </Tabs.Tab>
          ))}
        </Tabs>
        {currentTab === 1 && (
          <Section
            title="Active Ship Selection"
            buttons={
              <Button
                content="?"
                tooltip={"Hover over a ship's name to see its faction."}
              />
            }
          >
            <Flex direction="column" gap={1}>
              {ships.map((ship) => {
                const shipName = decodeHtmlEntities(ship.name);
                const shipFaction = ship.faction;
                const crewCount = ship.manifest
                  ? Object.keys(ship.manifest).length
                  : 0;

                return (
                  <Box
                    key={shipName}
                    style={{
                      background: '#2a2a2a',
                      border: '1px solid #444',
                      borderRadius: '8px',
                      padding: '12px',
                      marginBottom: '8px',
                    }}
                  >
                    {/* Шапка: Название + бейджи + мемо + кнопка */}
                    <Box
                      style={{
                        borderTop: '1px solid #444',
                        borderBottom: '1px solid #444',
                        padding: '8px 0',
                        marginBottom: '8px',
                      }}
                    >
                      <Flex align="center" justify="space-between" wrap>
                        {/* Левая часть: название + бейджи */}
                        <Flex.Item>
                          <Flex align="center" gap={1}>
                            <Box
                              mr={1}
                              bold
                              style={{ fontSize: '16px', color: '#fff' }}
                            >
                              {shipName}
                            </Box>
                            <Box
                              className="chip"
                              title="Класс корабля"
                              style={{
                                display: 'inline-flex',
                                alignItems: 'center',
                                padding: '0 6px',
                                height: '20px',
                                borderRadius: '6px',
                                fontSize: '12px',
                                lineHeight: '18px',
                                background: 'rgba(255,255,255,0.06)',
                                border: '1px solid rgba(255,255,255,0.12)',
                                marginRight: '4px',
                                color: '#fff',
                              }}
                            >
                              {ship.class}
                            </Box>
                            <Box
                              className="chip chip--faction"
                              title="Фракция"
                              style={{
                                display: 'inline-flex',
                                alignItems: 'center',
                                padding: '0 6px',
                                height: '20px',
                                borderRadius: '6px',
                                fontSize: '12px',
                                lineHeight: '18px',
                                background: getFactionColor(shipFaction).bg,
                                border: '1px solid rgba(255,255,255,0.12)',
                                marginRight: '4px',
                                color: getFactionColor(shipFaction).text,
                              }}
                            >
                              {shipFaction}
                            </Box>
                            <Box
                              className="chip"
                              title="Экипаж"
                              style={{
                                display: 'inline-flex',
                                alignItems: 'center',
                                padding: '0 6px',
                                height: '20px',
                                borderRadius: '6px',
                                fontSize: '12px',
                                lineHeight: '18px',
                                background: 'rgba(255,255,255,0.06)',
                                border: '1px solid rgba(255,255,255,0.12)',
                                marginRight: '4px',
                                color: '#fff',
                              }}
                            >
                              👥{' '}
                              <span style={{ color: '#2ECC71' }}>
                                {crewCount}
                              </span>
                            </Box>
                          </Flex>
                        </Flex.Item>

                        {/* Правая часть: Мемо + кнопка */}
                        <Flex.Item>
                          <Flex align="center" gap={1}>
                            <Box
                              title={
                                ship.memo
                                  ? decodeHtmlEntities(ship.memo)
                                  : 'Мемо пусто'
                              }
                              style={{
                                padding: '4px 8px',
                                borderRadius: '6px',
                                cursor: 'help',
                                background: 'rgba(255,255,255,0.06)',
                                border: '1px solid rgba(255,255,255,0.12)',
                                fontSize: '12px',
                                color: '#ccc',
                                display: 'inline-flex',
                                alignItems: 'center',
                                height: '20px',
                                marginRight: '12px',
                              }}
                            >
                              Мемо Капитана
                            </Box>
                            <Button
                              content={
                                ship.joinMode === applyStates.apply
                                  ? 'Apply'
                                  : 'Вступить в команду'
                              }
                              color={
                                ship.joinMode === applyStates.apply
                                  ? 'average'
                                  : 'good'
                              }
                              fluid={false}
                              onClick={() => {
                                setSelectedShipRef(ship.ref);
                                setCurrentTab(2);
                                const newTab = {
                                  name: 'Job Select',
                                  tab: 2,
                                };
                                const tabExists = shownTabs.some(
                                  (tab) =>
                                    tab.name === newTab.name &&
                                    tab.tab === newTab.tab
                                );
                                if (tabExists) {
                                  return;
                                }
                                setShownTabs((tabs) => {
                                  logger.log(tabs);
                                  const newTabs = [...tabs];
                                  newTabs.splice(1, 0, newTab);
                                  return newTabs;
                                });
                              }}
                            />
                          </Flex>
                        </Flex.Item>
                      </Flex>
                    </Box>
                  </Box>
                );
              })}
            </Flex>
          </Section>
        )}
        {currentTab === 3 && !data.selectedFaction && (
          <Section
            title="Ship Purchase"
            buttons={
              <Button
                icon="question"
                tooltip={
                  <>
                    Цветные линии показывают отношения между фракциями:
                    <br />
                    <br />
                    <div>Зелёный — Союз</div>
                    <div>Светло-синий — Положительные</div>
                    <div>Серый — Нейтральные</div>
                    <div>Оранжевый — Отрицательные</div>
                    <div>Красный — Война</div>
                  </>
                }
              />
            }
          >
            <FactionButtons />
          </Section>
        )}
        {currentTab === 3 && data.selectedFaction && (
          <Section
            title={`Ship Purchase - ${data.selectedFaction}`}
            buttons={
              <Button content="Back" onClick={() => act('back_factions')} />
            }
          >
            <ShipBrowser />
          </Section>
        )}
        {currentTab === 2 && (
          <>
            <Section
              title={`Ship Details - ${decodeHtmlEntities(selectedShip.name)}`}
            >
              <LabeledList>
                <LabeledList.Item label="Ship Class">
                  {selectedShip.class}
                </LabeledList.Item>
                <LabeledList.Item label="Ship Faction">
                  {selectedShip.faction}
                </LabeledList.Item>
                <LabeledList.Item label="Ship Join Status">
                  {selectedShip.joinMode}
                </LabeledList.Item>
                <LabeledList.Item label="Ship Memo">
                  {decodeHtmlEntities(selectedShip.memo) || 'No Memo'}
                </LabeledList.Item>
              </LabeledList>
            </Section>
            <Collapsible title={'Ship Info'}>
              <LabeledList>
                <LabeledList.Item label="Ship Description">
                  {selectedShip.desc || 'No Description'}
                </LabeledList.Item>
                <LabeledList.Item label="Ship Tags">
                  {(selectedShip.tags && selectedShip.tags.join(', ')) ||
                    'No Tags Set'}
                </LabeledList.Item>
              </LabeledList>
            </Collapsible>
            <Section
              title="Job Selection"
              buttons={
                <Button
                  content="Back"
                  onClick={() => {
                    setCurrentTab(1);
                  }}
                />
              }
            >
              <Table>
                <Table.Row header>
                  <Table.Cell collapsing>Join</Table.Cell>
                  <Table.Cell>Job Name</Table.Cell>
                  <Table.Cell>Slots</Table.Cell>
                  <Table.Cell>Min. Playtime</Table.Cell>
                </Table.Row>
                {selectedShip.jobs.map((job) => (
                  <Table.Row key={job.name}>
                    <Table.Cell>
                      <Button
                        content="Select"
                        tooltip={
                          (!data.autoMeet &&
                            data.playMin < job.minTime &&
                            'You do not have enough playtime to play this job.') ||
                          (data.officerBanned &&
                            'You are banned from playing officer roles')
                        }
                        disabled={
                          (!data.autoMeet && data.playMin < job.minTime) ||
                          (data.officerBanned && job.officer)
                        }
                        onClick={() => {
                          act('join', {
                            ship: selectedShip.ref,
                            job: job.ref,
                          });
                        }}
                      />
                    </Table.Cell>
                    <Table.Cell>{job.name}</Table.Cell>
                    <Table.Cell>{job.slots}</Table.Cell>
                    <Table.Cell>
                      {formatShipTime(job.minTime, data.playMin, data.autoMeet)}
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </>
        )}
      </Window.Content>
    </Window>
  );
};

const formatShipTime = (minTime, playMin, autoMeet) => {
  return (
    (minTime <= 0 && '-') ||
    minTime + 'm ' + ((!autoMeet && playMin < minTime && '(Unmet)') || '(Met)')
  );
};
