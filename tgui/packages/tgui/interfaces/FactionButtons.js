import { useBackend, useLocalState } from '../backend';
import { Box, Button } from '../components';
import { resolveAsset } from '../assets';

// Список всех доступных фракций (7 по периметру + Other в центре)
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
    color: 'rgb(145, 78, 1)',
  },
  {
    id: 'solfed',
    name: 'SolFed',
    short: 'SF',
    color: '#283674',
  },
  {
    id: 'independent',
    name: 'Independent',
    short: 'IND',
    color: '#7E6641',
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
];

// Центральная фракция
const CENTRAL_FACTION = {
  id: 'other',
  name: 'Ships',
  short: 'OTHER',
  color: '#9333ea',
};

// Легенда типов отношений
const RELATION_TYPES = {
  union: { name: 'Союз', color: '#2ECC71' }, // Зеленый
  positive: { name: 'Положительные', color: '#87CEEB' }, // Светло-синий
  neutral: { name: 'Нейтральные', color: '#808080' }, // Серый
  negative: { name: 'Отрицательные', color: '#FFA500' }, // Оранжевый
  war: { name: 'Война', color: '#FF0000' }, // Красный
};

// Полная система отношений между всеми 7 фракциями (21 линия)
const FACTION_RELATIONS = [
  // Nanotrasen отношения (6 линий)
  { from: 'nanotrasen', to: 'solfed', type: 'union' },
  { from: 'nanotrasen', to: 'elysium', type: 'negative' },
  { from: 'nanotrasen', to: 'inteq', type: 'neutral' },
  { from: 'nanotrasen', to: 'syndicate', type: 'war' },
  { from: 'nanotrasen', to: 'pirates', type: 'war' },
  { from: 'nanotrasen', to: 'independent', type: 'neutral' },

  // SolFed отношения (5 линий - исключаем Nanotrasen, так как уже есть)
  { from: 'solfed', to: 'elysium', type: 'war' },
  { from: 'solfed', to: 'inteq', type: 'neutral' },
  { from: 'solfed', to: 'syndicate', type: 'negative' },
  { from: 'solfed', to: 'pirates', type: 'war' },
  { from: 'solfed', to: 'independent', type: 'neutral' },

  // Elysium отношения (4 линии - исключаем Nanotrasen и SolFed)
  { from: 'elysium', to: 'inteq', type: 'neutral' },
  { from: 'elysium', to: 'syndicate', type: 'positive' },
  { from: 'elysium', to: 'pirates', type: 'war' },
  { from: 'elysium', to: 'independent', type: 'neutral' },

  // InteQ отношения (3 линии - исключаем Nanotrasen, SolFed и Elysium)
  { from: 'inteq', to: 'syndicate', type: 'neutral' },
  { from: 'inteq', to: 'pirates', type: 'war' },
  { from: 'inteq', to: 'independent', type: 'neutral' },

  // Syndicate отношения (2 линии - исключаем Nanotrasen, SolFed, Elysium и InteQ)
  { from: 'syndicate', to: 'pirates', type: 'war' },
  { from: 'syndicate', to: 'independent', type: 'neutral' },

  // Pirates отношения (1 линия - исключаем всех кроме Independent)
  { from: 'pirates', to: 'independent', type: 'war' },
];

// Функция для получения цветов фракций (для использования в других файлах)
export const getFactionColor = (factionName) => {
  if (!factionName) return { bg: '#666', text: 'white' };

  const factionLower = String(factionName).toLowerCase();

  // Цвета фракций для стилизации
  const FACTION_COLORS = {
    'nanotrasen': { bg: '#283674', text: 'white' },
    'syndicate': { bg: '#9C0808', text: 'white' },
    'inteq': { bg: '#4D291F', text: 'rgb(230, 200, 120)' },
    'inteq risk management group': {
      bg: '#4D291F',
      text: 'rgb(230, 200, 120)',
    },
    'solfed': { bg: '#191970', text: '#FFD700' },
    'independent': { bg: '#7E6641', text: '#FFD700' },
    'elysium': { bg: '#006400', text: 'white' },
    'pirates': { bg: '#000000', text: 'white' },
    'other': { bg: '#000080', text: 'white' },
  };

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

export const FactionButtons = (props, context) => {
  const { act } = useBackend(context);
  const { showCloseButton = false } = props;

  // Состояние для отслеживания наведенной фракции
  const [hoveredFaction, setHoveredFaction] = useLocalState(
    context,
    'hoveredFaction',
    null
  );

  return (
    <>
      <Box style={{ textAlign: 'center', position: 'relative' }}>
        {/* Семиугольник с кнопками и центральной фракцией */}
        <Box
          style={{
            position: 'relative',
            width: '450px',
            height: '450px',
            margin: '0 auto',
          }}
        >
          {/* Математический расчет позиций семиугольника */}
          {(() => {
            const centerX = 225;
            const centerY = 225;
            const radius = 165; // Расстояние от центра до кнопок (увеличено на ~18%)

            // 7 углов семиугольника (360° / 7 = ~51.4° между углами)
            // Начинаем с -90° чтобы первая кнопка была сверху
            const angles = [-90, -38.6, 12.8, 64.2, 115.6, 167, 218.4];

            // Позиции кнопок по периметру семиугольника
            const positions = angles.map((angle, index) => {
              const x = centerX + radius * Math.cos((angle * Math.PI) / 180);
              const y = centerY + radius * Math.sin((angle * Math.PI) / 180);
              return { x, y, faction: FACTIONS[index] };
            });

            return (
              <>
                {/* Цветные линии отношений */}
                <svg
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%',
                    zIndex: 1,
                  }}
                >
                  {/* Линии отношений между фракциями */}
                  {FACTION_RELATIONS.map((relation, index) => {
                    const fromIndex = FACTIONS.findIndex(
                      (f) => f.id === relation.from
                    );
                    const toIndex = FACTIONS.findIndex(
                      (f) => f.id === relation.to
                    );

                    if (fromIndex === -1 || toIndex === -1) return null;

                    const fromPos = positions[fromIndex];
                    const toPos = positions[toIndex];

                    // Определяем, должна ли линия быть подсвечена
                    const isHighlighted =
                      hoveredFaction &&
                      (relation.from === hoveredFaction ||
                        relation.to === hoveredFaction);

                    // Определяем, должна ли линия быть приглушена
                    const isDimmed = hoveredFaction && !isHighlighted;

                    return (
                      <line
                        key={index}
                        x1={fromPos.x}
                        y1={fromPos.y}
                        x2={toPos.x}
                        y2={toPos.y}
                        stroke={RELATION_TYPES[relation.type].color}
                        strokeWidth={isHighlighted ? '5' : '3'}
                        opacity={isHighlighted ? '1' : isDimmed ? '0.2' : '0.7'}
                        style={{
                          filter: isHighlighted
                            ? 'drop-shadow(0 0 4px currentColor)'
                            : 'none',
                          transition: 'all 0.2s ease-in-out',
                        }}
                      />
                    );
                  })}
                </svg>

                {/* 7 фракций по периметру семиугольника */}
                {positions.map((pos, index) => (
                  <Box
                    key={index}
                    style={{
                      position: 'absolute',
                      top: `${pos.y - 50}px`, // Центрируем кнопку (100px высота / 2)
                      left: `${pos.x - 50}px`, // Центрируем кнопку (100px ширина / 2)
                      zIndex: 2,
                    }}
                  >
                    <FactionButton
                      faction={pos.faction}
                      context={context}
                      act={act}
                      hoveredFaction={hoveredFaction}
                      setHoveredFaction={setHoveredFaction}
                    />
                  </Box>
                ))}

                {/* Центральная кнопка Other */}
                <Box
                  style={{
                    position: 'absolute',
                    top: `${centerY - 40}px`,
                    left: `${centerX - 40}px`,
                    zIndex: 3,
                  }}
                >
                  <FactionButton
                    faction={CENTRAL_FACTION}
                    context={context}
                    act={act}
                    hoveredFaction={hoveredFaction}
                    setHoveredFaction={setHoveredFaction}
                    isCentral
                  />
                </Box>
              </>
            );
          })()}
        </Box>
      </Box>

      {showCloseButton && (
        <Box mt={2}>
          <Button color="red" onClick={() => act('close')}>
            Закрыть
          </Button>
        </Box>
      )}
    </>
  );
};

// Компонент для отдельной кнопки фракции
const FactionButton = ({
  faction,
  context,
  act,
  hoveredFaction,
  setHoveredFaction,
  isCentral = false,
}) => {
  const buttonSize = isCentral ? '80px' : '96px';

  return (
    <Box
      style={{
        width: buttonSize,
        height: buttonSize,
        cursor: 'pointer',
      }}
      onClick={() => act('open_faction', { faction: faction.id })}
      onMouseEnter={() => setHoveredFaction(faction.id)}
      onMouseLeave={() => setHoveredFaction(null)}
    >
      <FactionLogo faction={faction} context={context} isCentral={isCentral} />
      <Box mt={isCentral ? 0.2 : 0.5} textAlign="center" fontSize="11px">
        {faction.name}
      </Box>
    </Box>
  );
};

// Показывает логотип фракции или fallback если картинка не загрузилась
const FactionLogo = ({ faction, context, isCentral = false }) => {
  const [hasError, setHasError] = useLocalState(
    context,
    `faction_logo_error_${faction.id}`,
    false
  );

  const logoSize = isCentral ? '80px' : '96px';

  if (hasError) {
    return (
      <Box
        style={{
          width: logoSize,
          height: logoSize,
          background: faction.color,
          color: 'white',
          fontSize: '14px',
          fontWeight: 'bold',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          border: '1px solid ' + faction.color,
          borderRadius: '4px',
          pointerEvents: 'none', // Fix for cursor flickering
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
        width: logoSize,
        height: logoSize,
        border: 'none',
        borderRadius: '0',
        background: 'transparent',
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        pointerEvents: 'none', // Fix for cursor flickering
      }}
    >
      <Box
        as="img"
        src={imageSrc}
        style={{
          width: logoSize,
          height: logoSize,
          objectFit: 'contain',
          pointerEvents: 'none', // Fix for cursor flickering
        }}
        onError={() => {
          setHasError(true);
        }}
      />
    </Box>
  );
};
