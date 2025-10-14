import { useBackend } from '../backend';
import {
  Button,
  Section,
  LabeledList,
  Box,
  NoticeBox,
  Input,
  Stack,
} from '../components';
import { NtosWindow } from '../layouts';

// ⛧ MARKER SCRIPTORIUM ⛧
// Gothic/Dead Space themed PROGRESSIVE sequence capture game
// Players must click each symbol in target_sequence as it scrolls by
// Wrong click = FULL RESET! High tension cognitive challenge!
const MarkerScriptorium = ({ session, act }) => {
  const targetSequence = session.payload?.target_sequence || [];
  const scrollingPool = session.payload?.scrolling_pool || [];
  const progress = session.payload?.current_progress || 0;
  const progressSymbols = session.payload?.progress_symbols || [];
  const position = session.payload?.current_position || 0;
  const result = session.payload?.result || '';

  // Next symbol player needs to capture
  const nextSymbol = targetSequence[progress] || '?';

  // Get 5 visible symbols from scrolling pool (2 left, center, 2 right)
  const getVisibleSymbols = () => {
    const visible = [];
    for (let offset = -2; offset <= 2; offset++) {
      const index =
        (((position + offset) % scrollingPool.length) + scrollingPool.length) %
        scrollingPool.length;
      const symbol = scrollingPool[index] || '?';
      const isCenterSymbol = offset === 0;

      visible.push(
        <Box
          key={offset}
          style={{
            display: 'inline-block',
            fontSize: isCenterSymbol ? '60px' : '48px',
            color: isCenterSymbol ? '#ff0000' : '#8b0000',
            textShadow: isCenterSymbol
              ? '0 0 20px rgba(255, 0, 0, 0.9), 0 0 40px rgba(255, 0, 0, 0.5)'
              : '0 0 8px rgba(139, 0, 0, 0.6)',
            opacity: isCenterSymbol ? 1.0 : 0.4,
            margin: '0 8px',
            transition: 'all 0.2s ease-in-out',
            transform: isCenterSymbol ? 'scale(1.2)' : 'scale(1.0)',
            fontFamily: 'serif',
            fontWeight: 'bold',
          }}
        >
          {symbol}
        </Box>
      );
    }
    return visible;
  };

  return (
    <Section
      title="⛧ MARKER SCRIPTORIUM ⛧"
      style={{
        backgroundColor: '#0a0a0a',
        border: '2px solid #8b0000',
        boxShadow: '0 0 20px rgba(139, 0, 0, 0.3)',
      }}
    >
      {/* Target Sequence with Visual Progress Indicators */}
      <Box textAlign="center" mb={2}>
        <Box
          fontSize="14px"
          color="label"
          mb={1}
          style={{ letterSpacing: '2px' }}
        >
          SIGNUM SEQUENTIA:
        </Box>

        {/* Target symbols with color-coded status */}
        <Box fontSize="40px" style={{ letterSpacing: '12px' }}>
          {targetSequence.map((sym, idx) => {
            let symbolColor, symbolGlow, symbolOpacity, symbolAnimation;

            if (idx < progress) {
              // Already captured - GREEN
              symbolColor = '#00ff00';
              symbolGlow = '0 0 15px rgba(0, 255, 0, 0.9)';
              symbolOpacity = 1.0;
              symbolAnimation = 'none';
            } else if (idx === progress) {
              // NEXT TARGET - ORANGE/YELLOW, PULSING
              symbolColor = '#ffaa00';
              symbolGlow =
                '0 0 20px rgba(255, 170, 0, 1), 0 0 40px rgba(255, 170, 0, 0.6)';
              symbolOpacity = 1.0;
              symbolAnimation = 'pulse 1s infinite';
            } else {
              // Waiting - RED, DIMMED
              symbolColor = '#8b0000';
              symbolGlow = '0 0 5px rgba(139, 0, 0, 0.5)';
              symbolOpacity = 0.4;
              symbolAnimation = 'none';
            }

            return (
              <span
                key={idx}
                style={{
                  color: symbolColor,
                  textShadow: symbolGlow,
                  opacity: symbolOpacity,
                  display: 'inline-block',
                  margin: '0 4px',
                  transition: 'all 0.3s ease',
                  animation: symbolAnimation,
                  fontFamily: 'serif',
                  fontWeight: 'bold',
                }}
              >
                {sym}
              </span>
            );
          })}
        </Box>
      </Box>

      {/* Scrolling Symbols Pool */}
      <Box
        textAlign="center"
        mb={2}
        style={{
          padding: '20px 10px',
          backgroundColor: '#1a1a1a',
          border: '1px solid #4a0000',
          boxShadow: 'inset 0 0 30px rgba(139, 0, 0, 0.4)',
          minHeight: '140px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {getVisibleSymbols()}
      </Box>

      {/* Alignment Marker (static arrow) */}
      <Box
        textAlign="center"
        style={{
          fontSize: '36px',
          color: '#00ff00',
          textShadow: '0 0 20px rgba(0, 255, 0, 0.8)',
          marginTop: '-60px',
          marginBottom: '20px',
        }}
      >
        ▼
      </Box>

      {/* Capture Button - Shows current target */}
      <Box textAlign="center" mb={2}>
        <Button
          color="bad"
          fontSize="12px"
          disabled={session.solved}
          style={{
            backgroundColor: '#8b0000',
            border: '2px solid #ff0000',
            boxShadow: '0 0 15px rgba(255, 0, 0, 0.5)',
            fontFamily: 'serif',
            letterSpacing: '2px',
            padding: '8px 17px',
          }}
          onClick={() =>
            act('submit_step', { ma: 'press', position: position })
          }
        >
          ⛧ CAPTURE: {nextSymbol} ({progress + 1}/{targetSequence.length}) ⛧
        </Button>
      </Box>

      {/* Enhanced Result Messages */}
      {result === 'correct' &&
        !session.solved &&
        progressSymbols.length > 0 && (
          <NoticeBox color="good" textAlign="center">
            SYMBOL CAPTURED! ({progress}/{targetSequence.length})
          </NoticeBox>
        )}
      {result === 'reset' && (
        <NoticeBox color="bad" textAlign="center">
          WRONG SYMBOL! SEQUENCE RESET!
          <br />
          {targetSequence.length > 0 && targetSequence[0] && (
            <Box fontSize="12px" mt={0.5}>
              Start from {targetSequence[0]} again
            </Box>
          )}
        </NoticeBox>
      )}
      {result === 'complete' && (
        <NoticeBox color="good" textAlign="center">
          CONVERGENCE COMPLETE!
          <br />
          <Box fontSize="12px" mt={0.5}>
            SEQUENCE: {progressSymbols.join(' → ')}
          </Box>
        </NoticeBox>
      )}

      {/* Latin Flavor Text */}
      <Box
        textAlign="center"
        mt={2}
        style={{
          fontSize: '13px',
          color: '#8b0000',
          fontFamily: 'serif',
          fontStyle: 'italic',
          letterSpacing: '1px',
          opacity: 0.8,
        }}
      >
        "Convergite signum... Make us whole."
      </Box>
    </Section>
  );
};

export const NtosCognitiveResearchSuite = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    PC_device_theme,
    simulation_active,
    score,
    difficulty,
    status_message,
    session,
    cooldown_remaining,
    is_admin,
    player_progress,
  } = data;

  return (
    <NtosWindow theme={PC_device_theme} width={400} height={500} resizable>
      <NtosWindow.Content scrollable>
        <Section title="Cognitive Research Suite">
          <LabeledList>
            <LabeledList.Item label="Status">{status_message}</LabeledList.Item>
            <LabeledList.Item label="Score">{score} points</LabeledList.Item>
            <LabeledList.Item label="Difficulty">
              Level {difficulty}
            </LabeledList.Item>
            {!!cooldown_remaining && (
              <LabeledList.Item label="Cooldown">
                {Math.ceil(cooldown_remaining / 10)} s
              </LabeledList.Item>
            )}
            {player_progress && (
              <LabeledList.Item label="Progress">
                {player_progress.completed} completed
                {player_progress.multiplier > 1.0 && (
                  <span> (x{player_progress.multiplier})</span>
                )}
              </LabeledList.Item>
            )}
          </LabeledList>

          <Box mt={1}>
            <Button
              icon="play"
              disabled={simulation_active || cooldown_remaining > 0}
              onClick={() => act('begin_simulation')}
            >
              Begin Simulation
            </Button>
            <Button icon="file" ml={1} onClick={() => act('collect_data')}>
              Collect Data
            </Button>
          </Box>
        </Section>

        {simulation_active ? (
          <Section
            title={`${session?.title || 'Cognitive Simulation'} — ${
              session?.subtitle || 'Session'
            }`}
          >
            <Box mb={2}>
              <strong>Simulation in progress...</strong>
              <br />
              Complete the cognitive pattern analysis to gain research points.
            </Box>

            <Box mb={2}>
              {session?.mode === 'lightsout' ? (
                (() => {
                  const grid = Array.isArray(session?.payload)
                    ? session.payload
                    : session?.payload?.grid;
                  if (!Array.isArray(grid)) return null;
                  return (
                    <Box>
                      {grid.map((row, ri) => (
                        <Box key={ri}>
                          {row.map((cell, ci) => (
                            <Button
                              key={`${ri}-${ci}`}
                              width={2}
                              selected={cell === '●'}
                              onClick={() =>
                                act('step', { row: ri + 1, col: ci + 1 })
                              }
                            >
                              {cell}
                            </Button>
                          ))}
                        </Box>
                      ))}
                    </Box>
                  );
                })()
              ) : session?.mode === 'marker' ? (
                <MarkerScriptorium session={session} act={act} />
              ) : session?.mode === 'sudoku4' ? (
                <Section title="Sudoku 4x4">
                  <Box>
                    {Array.isArray(session?.payload?.grid) &&
                      session.payload.grid.map((row, ri) => (
                        <Box key={ri}>
                          {row.map((val, ci) => (
                            <Button
                              key={`${ri}-${ci}`}
                              width={2}
                              disabled={session.payload?.fixed?.[ri]?.[ci]}
                              onClick={() =>
                                act('submit_step', {
                                  sd: 'cycle',
                                  row: ri + 1,
                                  col: ci + 1,
                                })
                              }
                            >
                              {val || '·'}
                            </Button>
                          ))}
                        </Box>
                      ))}
                  </Box>
                </Section>
              ) : session?.mode === 'logic' ? (
                <Section title="Logic">
                  <Box mb={1}>
                    Operator: {session.payload?.operator} · Target output:{' '}
                    {session.payload?.target} · Current:{' '}
                    {session.payload?.output}
                  </Box>
                  <Box>
                    {(session.payload?.inputs || []).map((v, i) => (
                      <Button
                        key={i}
                        selected={!!v}
                        onClick={() =>
                          act('submit_step', { lg: 'toggle', idx: i + 1 })
                        }
                      >
                        {v ? 1 : 0}
                      </Button>
                    ))}
                  </Box>
                </Section>
              ) : session?.mode === 'cryptogram' ? (
                <Section title="Cryptogram">
                  <LabeledList>
                    <LabeledList.Item label="Encrypted">
                      {(session.payload?.encrypted_message || [])
                        .map(String)
                        .join(' ')}
                    </LabeledList.Item>

                    <LabeledList.Item label="Your Input">
                      <Input
                        fluid
                        value={session.payload?.user_input_text || ''}
                        placeholder="Type decoded text (A..Z)"
                        onChange={(e, value) =>
                          act('submit_step', {
                            cg: 'set',
                            text: value,
                          })
                        }
                      />
                    </LabeledList.Item>

                    <LabeledList.Item label="Status">
                      {session.payload?.status === 'ok'
                        ? '✅ Correct'
                        : session.payload?.status === 'fail'
                        ? '❌ Try again'
                        : '…'}
                    </LabeledList.Item>

                    <LabeledList.Item label="Hints">
                      {session.payload?.hints_used || 0}/
                      {session.payload?.max_hints || 0}
                    </LabeledList.Item>

                    <LabeledList.Item label="Attempts">
                      {session.payload?.attempts || 0}
                    </LabeledList.Item>
                  </LabeledList>

                  <Stack mt={1} justify="space-between">
                    <Stack.Item grow>
                      <Button
                        onClick={() => act('submit_step', { cg: 'check' })}
                        color="good"
                      >
                        Check Answer
                      </Button>
                      <Button
                        onClick={() => act('submit_step', { cg: 'clear' })}
                        ml={1}
                      >
                        Clear
                      </Button>
                      <Button
                        onClick={() => act('submit_step', { cg: 'hint' })}
                        ml={1}
                        disabled={
                          (session.payload?.hints_used || 0) >=
                          (session.payload?.max_hints || 0)
                        }
                      >
                        Hint
                      </Button>
                    </Stack.Item>
                    <Stack.Item>
                      <span style={{ opacity: 0.7 }}>
                        {session.payload?.hint}
                      </span>
                    </Stack.Item>
                  </Stack>
                </Section>
              ) : session?.mode === 'topsort' ? (
                <Section title="Wiring Order">
                  <Box color="label" mb={1}>
                    Click nodes to append to order. Solve when all edges go from
                    earlier to later nodes.
                  </Box>
                  <Box mb={1}>
                    {(session.payload?.nodes || []).map((n) => (
                      <Button
                        key={n}
                        disabled={(session.payload?.solution || []).includes(n)}
                        onClick={() => act('submit_step', { ts: 'push', n })}
                      >
                        {n}
                      </Button>
                    ))}
                    <Button
                      ml={1}
                      onClick={() => act('submit_step', { ts: 'back' })}
                    >
                      Back
                    </Button>
                  </Box>
                  <Box>
                    Order: {(session.payload?.solution || []).join(' → ')}
                    {Array.isArray(session.payload?.conflicts) &&
                      session.payload.conflicts.length > 0 && (
                        <Box color="bad" mt={1}>
                          Conflicts:{' '}
                          {session.payload.conflicts
                            .map((p) => `${p[0]}→${p[1]}`)
                            .join(', ')}
                        </Box>
                      )}
                    <Box mt={1}>
                      <Button
                        color="bad"
                        onClick={() => act('submit_step', { ts: 'reset' })}
                      >
                        Reset
                      </Button>
                    </Box>
                  </Box>
                </Section>
              ) : (
                <Box color={session?.solved ? 'good' : 'label'} fontSize="12px">
                  {session?.solved ? 'Solved — submit telemetry.' : ''}
                </Box>
              )}
            </Box>

            <Box mt={2}>
              <Button
                icon="check"
                color="good"
                onClick={() => act('complete_simulation')}
                disabled={!session?.solved}
              >
                Submit Telemetry
              </Button>
              {!!is_admin && (
                <Button
                  icon="magic"
                  color="default"
                  ml={1}
                  onClick={() => act('debug_solve')}
                >
                  Solved
                </Button>
              )}
              <Button
                icon="times"
                color="bad"
                ml={1}
                onClick={() => act('reset_simulation')}
              >
                Reset
              </Button>
            </Box>
          </Section>
        ) : null}

        <Section title="About">
          <Box fontSize="12px" color="label">
            <p>
              <strong>CRS</strong> collects cognitive metrics for R&D modeling.
              Complete simulations to gain research points.
            </p>
            <p>
              <strong>Access:</strong> Research personnel. Data is automatically
              forwarded to R&D systems.
            </p>
          </Box>
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
