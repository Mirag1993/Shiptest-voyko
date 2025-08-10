import { useBackend, useLocalState } from '../backend';
import { Box, Button, Flex, Section, Stack } from '../components';
import { Window } from '../layouts';
import { resolveAsset } from '../assets';

// Список всех доступных фракций
const FACTIONS = [
  {
    id: 'nanotrasen',
    name: 'Nanotrasen',
    short: 'NT',
    color: '#283674',
  },
  {
    id: 'syndicate',
    name: 'Syndicate',
    short: 'SYN',
    color: '#B22C20',
  },
  {
    id: 'inteq',
    name: 'InteQ',
    short: 'IQ',
    color: '#7E6641',
  },
  {
    id: 'solfed',
    name: 'SolFed',
    short: 'SF',
    color: '#444e5f',
  },
  {
    id: 'independent',
    name: 'Independent',
    short: 'IND',
    color: '#A0A0A0',
  },
  {
    id: 'elysium',
    name: 'Elysium',
    short: 'ELY',
    color: '#FF6B35',
  },
  {
    id: 'pirates',
    name: 'Pirates',
    short: 'PIR',
    color: '#8B4513',
  },
  {
    id: 'other',
    name: 'Other',
    short: 'OTHER',
    color: '#9333ea',
  },
];

export const ShipFactionSelect = (props, context) => {
  const { act } = useBackend(context);

  return (
    <Window title="Меню выбора фракций" width={700} height={420} resizable>
      <Window.Content>
        <Section>
          <Stack vertical>
            {[0, 1].map((row) => (
              <Stack.Item key={row}>
                <Flex justify="center" wrap>
                  {FACTIONS.slice(row * 4, row * 4 + 4).map((f) => (
                    <Flex.Item key={f.id} mx={1} my={2}>
                      <Box
                        style={{
                          width: '100px',
                          height: '80px',
                          cursor: 'pointer',
                        }}
                        onClick={() => act('open_faction', { faction: f.id })}
                      >
                        <FactionLogo faction={f} context={context} />
                      </Box>
                      <Box mt={1} textAlign="center" fontSize="11px">
                        {f.name}
                      </Box>
                    </Flex.Item>
                  ))}
                </Flex>
              </Stack.Item>
            ))}
          </Stack>
          <Box mt={2}>
            <Button color="red" onClick={() => act('close')}>
              Закрыть
            </Button>
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};

// Показывает логотип фракции или fallback если картинка не загрузилась
const FactionLogo = ({ faction, context }) => {
  const [hasError, setHasError] = useLocalState(
    context,
    `faction_logo_error_${faction.id}`,
    false
  );

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
          pointerEvents: 'none',
        }}
      >
        {faction.short}
      </Box>
    );
  }

  // Показываем картинку
  const imageSrc = resolveAsset(`${faction.id}.png`);

  return (
    <Box
      style={{
        width: '96px',
        height: '64px',
        border: 'none',
        borderRadius: '0',
        background: 'transparent',
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        pointerEvents: 'none',
      }}
    >
      <Box
        as="img"
        src={imageSrc}
        style={{
          width: '96px',
          height: '64px',
          objectFit: 'contain',
          pointerEvents: 'none',
        }}
        onError={() => {
          setHasError(true);
        }}
      />
    </Box>
  );
};
