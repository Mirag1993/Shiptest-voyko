import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Section, Stack, Table } from '../components';
import { Window } from '../layouts';

const FACTIONS = [
  {
    id: 'nanotrasen',
    name: 'Nanotrasen',
    short: 'NT',
    color: '#283674',
    matches: ['Nanotrasen', 'N+S Logistics', 'Vigilitas Interstellar'],
  },
  {
    id: 'syndicate',
    name: 'Syndicate',
    short: 'SYN',
    color: '#B22C20',
    matches: [
      'Syndicate',
      'New Gorlex Republic',
      'CyberSun',
      'Hardliners',
      'Student-Union of Naturalistic Sciences',
    ],
  },
  {
    id: 'inteq',
    name: 'InteQ',
    short: 'IQ',
    color: '#7E6641',
    matches: ['Inteq Risk Management Group'],
  },
  {
    id: 'solfed',
    name: 'SolFed',
    short: 'SF',
    color: '#444e5f',
    matches: ['SolFed', 'Solar Confederation'],
  },
  {
    id: 'independent',
    name: 'Independent',
    short: 'IND',
    color: '#A0A0A0',
    matches: ['Independent', 'Frontiersmen Fleet'],
  },
  {
    id: 'other',
    name: 'Other',
    short: 'OTHER',
    color: '#9333ea',
    matches: [],
  },
];

export const ShipSelectRework = (props, context) => {
  const { act, data } = useBackend(context);
  const [selectedFaction, setSelectedFaction] = useLocalState(
    context,
    'selectedFaction',
    null
  );

  return (
    <Window title="Ship Selection" width={860} height={640} resizable>
      <Window.Content scrollable>
        {!selectedFaction ? (
          <FactionSelection
            act={act}
            setSelectedFaction={setSelectedFaction}
            context={context}
          />
        ) : (
          <ShipSelection
            act={act}
            data={data}
            selectedFaction={selectedFaction}
            setSelectedFaction={setSelectedFaction}
          />
        )}
      </Window.Content>
    </Window>
  );
};

const FactionSelection = ({ act, setSelectedFaction, context }) => {
  const handleFactionSelect = (faction) => {
    setSelectedFaction(faction);
  };

  return (
    <Section title="Меню выбора фракций" textAlign="center">
      <Box mb={2} color="gray">
        Выберите фракцию для отображения доступных кораблей
      </Box>

      <Stack>
        <Stack.Item>
          <Flex direction="row" wrap="wrap" justify="center">
            {FACTIONS.slice(0, 3).map((faction) => (
              <Flex.Item key={faction.id} mx={1} mb={2}>
                <Box textAlign="center">
                  <Button
                    onClick={() => handleFactionSelect(faction)}
                    style={{
                      width: '120px',
                      height: '80px',
                      padding: '4px',
                      border: `2px solid ${faction.color}`,
                      borderRadius: '6px',
                      background: 'transparent',
                    }}
                  >
                    <Box mb={1}>
                      <FactionLogo faction={faction} context={context} />
                    </Box>
                  </Button>
                  <Box mt={1} fontSize="12px">
                    {faction.name}
                  </Box>
                </Box>
              </Flex.Item>
            ))}
          </Flex>
        </Stack.Item>

        <Stack.Item>
          <Flex direction="row" wrap="wrap" justify="center">
            {FACTIONS.slice(3).map((faction) => (
              <Flex.Item key={faction.id} mx={1} mb={2}>
                <Box textAlign="center">
                  <Button
                    onClick={() => handleFactionSelect(faction)}
                    style={{
                      width: '120px',
                      height: '80px',
                      padding: '4px',
                      border: `2px solid ${faction.color}`,
                      borderRadius: '6px',
                      background: 'transparent',
                    }}
                  >
                    <Box mb={1}>
                      <FactionLogo faction={faction} context={context} />
                    </Box>
                  </Button>
                  <Box mt={1} fontSize="12px">
                    {faction.name}
                  </Box>
                </Box>
              </Flex.Item>
            ))}
          </Flex>
        </Stack.Item>
      </Stack>

      <Box mt={3}>
        <Button onClick={() => act('close')} color="red">
          Закрыть
        </Button>
      </Box>
    </Section>
  );
};

const ShipSelection = (props, context) => {
  const { act, data, selectedFaction, setSelectedFaction } = props;
  const [selectedTags, setSelectedTags] = useLocalState(
    context,
    'selectedTags',
    []
  );
  const [sortBy, setSortBy] = useLocalState(context, 'sortBy', 'alphabet');

  // Получаем все доступные теги (из шаблонов)
  const templates = Array.isArray(data.templates) ? data.templates : [];
  const safeTemplates = templates.map((t) => ({
    name: typeof t?.name === 'string' ? t.name : '',
    faction: t?.faction || '',
    tags: Array.isArray(t?.tags) ? t.tags : [],
    desc: typeof t?.desc === 'string' ? t.desc : '',
    crewCount: Number(t?.crewCount) || 0,
    limit: Number(t?.limit) || 0,
    curNum: Number(t?.curNum) || 0,
    minTime: Number(t?.minTime) || 0,
    shortName: typeof t?.shortName === 'string' ? t.shortName : '',
  }));
  const activeShips = Array.isArray(data.ships) ? data.ships : [];

  // Собираем теги из всех кораблей (и templates и ships)
  const templateTags = safeTemplates.flatMap((s) => s.tags);
  const shipTags = activeShips.flatMap((s) =>
    Array.isArray(s?.tags) ? s.tags : []
  );
  const allTags = [...new Set([...templateTags, ...shipTags])].filter(
    (tag) => tag && tag.length > 0
  );

  // Фильтруем шаблоны (покупка) по фракции
  let filteredTemplates =
    safeTemplates.filter((ship) => {
      if (selectedFaction.id === 'other') {
        return !FACTIONS.slice(0, 5).some((faction) =>
          faction.matches.includes(ship.faction)
        );
      }
      return selectedFaction.matches.includes(ship.faction);
    }) || [];

  // Фильтруем активные корабли (для Join) по фракции
  const filteredActiveShips = activeShips.filter((ship) => {
    if (selectedFaction.id === 'other') {
      return !FACTIONS.slice(0, 5).some((faction) =>
        faction.matches.includes(ship.faction)
      );
    }
    return selectedFaction.matches.includes(ship.faction);
  });

  // Фильтруем по тегам
  if (selectedTags.length > 0) {
    filteredTemplates = filteredTemplates.filter((ship) =>
      selectedTags.every((tag) => ship.tags?.includes(tag))
    );
  }

  // Сортируем (на копии, чтобы не мутировать стейт между рендерами)
  const sortedTemplates = [...filteredTemplates];
  if (sortBy === 'alphabet') {
    sortedTemplates.sort((a, b) =>
      (a?.name || '').localeCompare(b?.name || '')
    );
  } else if (sortBy === 'crew') {
    sortedTemplates.sort(
      (a, b) => (Number(b?.crewCount) || 0) - (Number(a?.crewCount) || 0)
    );
  }

  const toggleTag = (tag) => {
    if (selectedTags.includes(tag)) {
      setSelectedTags(selectedTags.filter((t) => t !== tag));
    } else {
      setSelectedTags([...selectedTags, tag]);
    }
  };

  const clearAllTags = () => {
    setSelectedTags([]);
  };

  return (
    <Section title={`Выбор корабля - ${selectedFaction.name}`}>
      <Stack>
        <Stack.Item>
          <Button
            onClick={() => setSelectedFaction(null)}
            icon="arrow-left"
            mb={2}
          >
            ← Назад к выбору фракций
          </Button>
        </Stack.Item>

        {/* Фильтры по тегам */}
        <Stack.Item>
          <Box mb={2}>
            <Box mb={1} fontSize="14px" bold>
              Фильтр по тегам: ({allTags.length} доступно)
            </Box>
            {allTags.length === 0 ? (
              <Box color="gray" mb={2}>
                Теги не найдены. Проверьте конфигурацию кораблей.
              </Box>
            ) : (
              <Flex wrap="wrap">
                {allTags.map((tag) => (
                  <Flex.Item key={tag} mr={1} mb={1}>
                    <Button
                      onClick={() => toggleTag(tag)}
                      selected={selectedTags.includes(tag)}
                      style={{
                        border: selectedTags.includes(tag)
                          ? '2px solid #4ade80'
                          : '1px solid #6b7280',
                        background: selectedTags.includes(tag)
                          ? '#4ade8020'
                          : 'transparent',
                      }}
                    >
                      [{selectedTags.includes(tag) ? '✓' : ' '}] {tag}
                    </Button>
                  </Flex.Item>
                ))}
                {selectedTags.length > 0 && (
                  <Flex.Item mr={1} mb={1}>
                    <Button onClick={clearAllTags} color="red">
                      Очистить все
                    </Button>
                  </Flex.Item>
                )}
              </Flex>
            )}
          </Box>
        </Stack.Item>

        {/* Сортировка */}
        <Stack.Item>
          <Box mb={2}>
            <Box mb={1} fontSize="14px" bold>
              Сортировка:
            </Box>
            <Button
              selected={sortBy === 'alphabet'}
              onClick={() => setSortBy('alphabet')}
              mr={1}
            >
              По алфавиту
            </Button>
            <Button
              selected={sortBy === 'crew'}
              onClick={() => setSortBy('crew')}
            >
              По количеству экипажа
            </Button>
          </Box>
        </Stack.Item>

        {/* Активные корабли: Join */}
        <Stack.Item>
          <Box>
            <Box mb={2} fontSize="14px" bold>
              Активные корабли для вступления ({filteredActiveShips.length}):
            </Box>
            {filteredActiveShips.length === 0 ? (
              <Box color="gray" textAlign="center" p={3}>
                Нет активных кораблей
              </Box>
            ) : (
              <Stack vertical>
                {filteredActiveShips.map((ship) => (
                  <Stack.Item key={ship.ref}>
                    <Section title={`${ship.name} [${ship.class}]`}>
                      <Box mb={1} color="gray">
                        {ship.memo || 'Без заметки'}
                      </Box>
                      <Table>
                        <Table.Row header>
                          <Table.Cell collapsing>Действие</Table.Cell>
                          <Table.Cell>Роль</Table.Cell>
                          <Table.Cell>Слоты</Table.Cell>
                          <Table.Cell>Мин. время</Table.Cell>
                        </Table.Row>
                        {(ship.jobs || []).map((job) => (
                          <Table.Row key={job.ref}>
                            <Table.Cell>
                              <Button
                                onClick={() =>
                                  act('join', { ship: ship.ref, job: job.ref })
                                }
                                color="good"
                                tooltip={
                                  (!data.autoMeet &&
                                    data.playMin < job.minTime &&
                                    'Недостаточно игрового времени для этой роли.') ||
                                  (data.officerBanned &&
                                    job.officer &&
                                    'Вам запрещены офицерские роли')
                                }
                                disabled={
                                  (!data.autoMeet &&
                                    data.playMin < job.minTime) ||
                                  (data.officerBanned && job.officer)
                                }
                              >
                                Присоединиться
                              </Button>
                            </Table.Cell>
                            <Table.Cell>{job.name}</Table.Cell>
                            <Table.Cell>{job.slots}</Table.Cell>
                            <Table.Cell>
                              {job.minTime > 0 ? `${job.minTime}m` : '-'}
                            </Table.Cell>
                          </Table.Row>
                        ))}
                      </Table>
                    </Section>
                  </Stack.Item>
                ))}
              </Stack>
            )}
          </Box>
        </Stack.Item>

        {/* Список шаблонов: Покупка */}
        <Stack.Item>
          <Box>
            <Box mb={2} fontSize="14px" bold>
              Доступные к покупке ({filteredTemplates.length}):
            </Box>
            {filteredTemplates.length === 0 ? (
              <Box color="gray" textAlign="center" p={3}>
                Кораблей не найдено
              </Box>
            ) : (
              <Stack vertical>
                {sortedTemplates.map((ship, idx) => (
                  <Stack.Item key={`${ship.name}-${idx}`}>
                    <Flex
                      justify="space-between"
                      align="center"
                      p={2}
                      style={{
                        border: '1px solid #374151',
                        borderRadius: '4px',
                        marginBottom: '8px',
                      }}
                    >
                      <Flex.Item>
                        <Box fontSize="16px" bold>
                          {ship.name}
                        </Box>
                        <Box fontSize="12px" color="gray">
                          Экипаж: {ship.crewCount || 0} | Теги:{' '}
                          {ship.tags?.join(', ') || 'нет'}
                        </Box>
                        {typeof ship.desc === 'string' &&
                          ship.desc.length > 0 && (
                            <ShipDescription
                              description={ship.desc}
                              context={context}
                              shipName={ship.name}
                            />
                          )}
                      </Flex.Item>
                      <Flex.Item>
                        <Button
                          onClick={() => act('buy', { name: ship.name })}
                          color="green"
                          disabled={data.shipSpawning}
                        >
                          {data.shipSpawning ? 'Загрузка...' : 'Buy'}
                        </Button>
                      </Flex.Item>
                    </Flex>
                  </Stack.Item>
                ))}
              </Stack>
            )}
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// Компонент для отображения логотипа фракции с fallback
const FactionLogo = ({ faction, context }) => {
  const [imageLoaded, setImageLoaded] = useLocalState(
    context,
    `faction_logo_loaded_${faction.id}`,
    false
  );
  const [hasError, setHasError] = useLocalState(
    context,
    `faction_logo_error_${faction.id}`,
    false
  );

  // Если картинка не загрузилась - показываем fallback
  if (hasError) {
    return (
      <Box
        style={{
          width: '96px',
          height: '64px',
          background: faction.color,
          color: 'white',
          fontSize: '14px',
          fontWeight: 'bold',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          border: '1px solid ' + faction.color,
          borderRadius: '4px',
        }}
      >
        {faction.short}
      </Box>
    );
  }

  // Показываем картинку
  return (
    <Box
      style={{
        width: '96px',
        height: '64px',
        border: '1px solid ' + faction.color,
        borderRadius: '4px',
        background: faction.color + '10',
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <Box
        as="img"
        src={`faction_logos/${faction.id}.png`}
        style={{
          maxWidth: '94px',
          maxHeight: '62px',
          objectFit: 'contain',
        }}
        onLoad={() => setImageLoaded(true)}
        onError={() => setHasError(true)}
      />
    </Box>
  );
};

// Компонент для отображения описания корабля со сворачиванием
const ShipDescription = ({ description, context, shipName }) => {
  const [isExpanded, setIsExpanded] = useLocalState(
    context,
    `ship_desc_expanded_${shipName}`,
    false
  );

  // Проверяем нужно ли сворачивание (если описание длиннее 100 символов)
  const needsTruncation = description.length > 100;
  const shortDescription = needsTruncation
    ? description.substring(0, 100) + '...'
    : description;

  return (
    <Box fontSize="11px" color="lightgray" mt={1}>
      {needsTruncation && !isExpanded ? (
        <Box>
          {shortDescription}
          <Box
            as="span"
            color="cyan"
            style={{ cursor: 'pointer', marginLeft: '4px' }}
            onClick={() => setIsExpanded(true)}
          >
            [показать полностью]
          </Box>
        </Box>
      ) : (
        <Box>
          {description}
          {needsTruncation && (
            <Box
              as="span"
              color="cyan"
              style={{ cursor: 'pointer', marginLeft: '4px' }}
              onClick={() => setIsExpanded(false)}
            >
              [свернуть]
            </Box>
          )}
        </Box>
      )}
    </Box>
  );
};
