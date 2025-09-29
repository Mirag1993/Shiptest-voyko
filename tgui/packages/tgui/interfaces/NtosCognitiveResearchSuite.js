import { useBackend } from '../backend';
import { Button, Section, LabeledList, Box, NoticeBox } from '../components';
import { NtosWindow } from '../layouts';

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
              {session?.mode === 'lightsout' &&
              Array.isArray(session?.payload) ? (
                <Box>
                  {session.payload.map((row, ri) => (
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
              ) : session?.mode === 'mastermind' ? (
                <Section title="Mastermind">
                  <Box mb={1}>
                    <Box mb={0.5}>
                      Buffer (
                      {(Array.isArray(session.payload?.buffer)
                        ? session.payload.buffer.length
                        : 0) || 0}
                      /{session.payload?.code_length || 0}){': '}
                      {Array.isArray(session.payload?.buffer)
                        ? session.payload.buffer.join(' ')
                        : ''}
                    </Box>
                    <Box>
                      {(session.payload?.colors || []).map((c) => (
                        <Button
                          key={c}
                          onClick={() =>
                            act('submit_step', { mm: 'push', ch: c })
                          }
                        >
                          {c}
                        </Button>
                      ))}
                      <Button
                        ml={1}
                        onClick={() => act('submit_step', { mm: 'back' })}
                      >
                        Back
                      </Button>
                      <Button
                        ml={1}
                        onClick={() => act('submit_step', { mm: 'submit' })}
                        disabled={
                          !Array.isArray(session.payload?.buffer) ||
                          session.payload.buffer.length !==
                            (session.payload?.code_length || 0)
                        }
                      >
                        Submit
                      </Button>
                    </Box>
                  </Box>
                  {typeof session.payload?.last_result === 'object' && (
                    <NoticeBox>
                      Right color & position:{' '}
                      {session.payload.last_result.black || 0} · Right color,
                      wrong position: {session.payload.last_result.white || 0}
                    </NoticeBox>
                  )}
                  {Array.isArray(session.payload?.guesses) &&
                    session.payload.guesses.map((g, i) => (
                      <Box key={i} mb={0.25}>
                        {g.join(' ')} —{' '}
                        {session.payload?.feedback?.[i]?.black || 0}B /{' '}
                        {session.payload?.feedback?.[i]?.white || 0}W
                      </Box>
                    ))}
                </Section>
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
              {is_admin && (
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
