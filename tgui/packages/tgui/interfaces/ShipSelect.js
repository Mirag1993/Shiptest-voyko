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
import { FactionButtons, getFactionColor } from './FactionButtons';
import { ShipBrowser } from './ShipBrowser';

// Функция для обрезки текста с троеточием
const truncateText = (text, maxLength) => {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
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
                icon="question"
                tooltip={
                  'Для дополнительной информации наведите на интересующий вас элемент, например мемо капитана. Используйте манифест для просмотра текущих членов экипажа и их ролей.'
                }
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
                              title={shipName}
                              style={{
                                fontSize: '16px',
                                color: '#fff',
                                cursor: 'default',
                              }}
                            >
                              {truncateText(shipName, 15)}
                            </Box>
                            <Box
                              className="chip"
                              title="Класс корабля"
                              style={{
                                display: 'inline-flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                height: 22,
                                lineHeight: '22px',
                                padding: '0 8px',
                                minWidth: 110,
                                borderRadius: 6,
                                fontSize: 12,
                                background: 'rgba(255,255,255,0.06)',
                                border: '1px solid rgba(255,255,255,0.12)',
                                marginRight: '4px',
                                color: '#fff',
                                textAlign: 'center',
                                whiteSpace: 'nowrap',
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
                                justifyContent: 'center',
                                height: 22,
                                lineHeight: '22px',
                                padding: '0 8px',
                                minWidth: 110,
                                borderRadius: 6,
                                fontSize: 12,
                                background: getFactionColor(shipFaction).bg,
                                border: '1px solid rgba(255,255,255,0.12)',
                                marginRight: '4px',
                                color: getFactionColor(shipFaction).text,
                                textAlign: 'center',
                                whiteSpace: 'nowrap',
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
                                justifyContent: 'center',
                                height: 22,
                                lineHeight: '22px',
                                padding: '0 8px',
                                minWidth: 110,
                                borderRadius: 6,
                                fontSize: 12,
                                background: 'rgba(255,255,255,0.06)',
                                border: '1px solid rgba(255,255,255,0.12)',
                                marginRight: '4px',
                                color: '#fff',
                                textAlign: 'center',
                                whiteSpace: 'nowrap',
                              }}
                            >
                              👥:{' '}
                              <span style={{ color: '#2ECC71' }}>
                                {crewCount}
                              </span>
                            </Box>
                          </Flex>
                        </Flex.Item>

                        {/* Правая часть: Мемо + кнопка */}
                        <Flex.Item>
                          <Flex align="center" justify="flex-end">
                            <Flex.Item mr={1}>
                              <div
                                title={
                                  ship.memo
                                    ? decodeHtmlEntities(ship.memo)
                                    : 'Мемо пусто'
                                }
                                style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  height: 22,
                                  lineHeight: '22px',
                                  padding: '0 8px',
                                  minWidth: 110,
                                  borderRadius: 6,
                                  background: 'rgba(255,255,255,0.06)',
                                  border: '1px solid rgba(255,255,255,0.12)',
                                  fontSize: 12,
                                  color: '#ccc',
                                  textAlign: 'center',
                                  whiteSpace: 'nowrap',
                                  cursor: 'help',
                                }}
                              >
                                Мемо Капитана
                              </div>
                            </Flex.Item>

                            <Flex.Item>
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
                                  if (
                                    !shownTabs.some(
                                      (tab) =>
                                        tab.name === newTab.name &&
                                        tab.tab === newTab.tab
                                    )
                                  ) {
                                    setShownTabs((tabs) => {
                                      const t = [...tabs];
                                      t.splice(1, 0, newTab);
                                      return t;
                                    });
                                  }
                                }}
                              />
                            </Flex.Item>
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
