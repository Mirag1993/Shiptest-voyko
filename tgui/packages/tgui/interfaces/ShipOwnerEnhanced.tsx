import './ShipOwnerEnhanced.scss';

import {
  Box,
  Button,
  Divider,
  Flex,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  Table,
  Tabs,
} from 'tgui-core/components';
import { decodeHtmlEntities } from 'tgui-core/string';

import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';

type ShipOwnerData = {
  crew: [CrewData];
  jobs: [JobData];
  jobIncreaseAllowed: [string];
  memo: string;
  pending: boolean;
  joinMode: string;
  crew_share: number;
  cooldown: number;
  applications: [ApplicationData];
  isAdmin: boolean;
};

type ApplicationData = {
  ref: string;
  key: string;
  name: string;
  text: string;
  status: string;
  character_photo?: string;
  character_age?: number;
  character_quirks?: QuirkData[];
  character_species?: string;
  character_gender?: string;
  target_job?: string;
  denial_reason?: string;
  character_valid?: boolean;
};

type QuirkData = {
  name: string;
  value: number;
  color: string;
  desc: string;
};

type CrewData = {
  ref: string;
  name: string;
  allowed: boolean;
};

type JobData = {
  ref: string;
  name: string;
  slots: number;
  max: number;
  def: number;
};

export const ShipOwnerEnhanced = (props) => {
  return (
    <Window width={800} height={700}>
      <Window.Content scrollable>
        <ShipOwnerContent />
      </Window.Content>
    </Window>
  );
};

const ShipOwnerContent = () => {
  const { act, data } = useBackend<ShipOwnerData>();
  const [tab, setTab] = useLocalState('tab', 1);
  const {
    crew = [],
    jobs = [],
    memo,
    pending,
    joinMode,
    crew_share,
    cooldown = 1,
    applications = [],
    isAdmin,
    jobIncreaseAllowed = [],
  } = data;

  return (
    <div className="ship-owner-enhanced">
      <Section
        title={'Ship Management'}
        buttons={
          <Tabs>
            <Tabs.Tab selected={tab === 1} onClick={() => setTab(1)}>
              Ship, Applications
            </Tabs.Tab>
            <Tabs.Tab selected={tab === 2} onClick={() => setTab(2)}>
              Ship Owner Options
            </Tabs.Tab>
            <Tabs.Tab selected={tab === 3} onClick={() => setTab(3)}>
              Job Slots
            </Tabs.Tab>
          </Tabs>
        }
      >
        {(!memo || memo.length <= 0) && (
          <div className="NoticeBox">You need to set a ship memo!</div>
        )}
        {!!pending && (
          <div className="NoticeBox">You have pending applications!</div>
        )}
        {tab === 1 && (
          <>
            <LabeledList>
              <LabeledList.Item label="Join Settings">
                <Button
                  content={joinMode}
                  icon="bed"
                  color={
                    joinMode === 'Open'
                      ? 'good'
                      : joinMode === 'Apply'
                        ? 'average'
                        : 'bad'
                  }
                  onClick={() => act('cycleJoin')}
                />
                <Button
                  content="Check / Alter Memo"
                  onClick={() => act('memo')}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Current Memo">
                {decodeHtmlEntities(memo)}
              </LabeledList.Item>
            </LabeledList>
            <Divider />
            {applications.length === 0 ? (
              <Box textAlign="center" color="gray" py={2}>
                No applications received yet
              </Box>
            ) : (
              <Stack vertical>
                {applications.map((app: ApplicationData) => (
                  <ApplicationCard key={app.ref} app={app} act={act} />
                ))}
              </Stack>
            )}
          </>
        )}
        {tab === 2 && (
          <Table>
            <Table.Row header>
              <Table.Cell>Crewmember</Table.Cell>
              <Table.Cell>Can be owner</Table.Cell>
              <Table.Cell>Transfer Ownership</Table.Cell>
            </Table.Row>
            {crew.map((crew_data: CrewData) => (
              <Table.Row key={crew_data.name}>
                <Table.Cell>{crew_data.name}</Table.Cell>
                <Table.Cell>
                  <Button.Checkbox
                    content="Candidate"
                    checked={crew_data.allowed}
                    onClick={() =>
                      act('toggleCandidate', {
                        ref: crew_data.ref,
                      })
                    }
                  />
                </Table.Cell>
                <Table.Cell>
                  <Button
                    content="Transfer Owner"
                    onClick={() =>
                      act('transferOwner', {
                        ref: crew_data.ref,
                      })
                    }
                  />
                </Table.Cell>
              </Table.Row>
            ))}
            <LabeledList>
              <LabeledList.Item label="Crew Profit Share">
                <NumberInput
                  animated
                  unit="%"
                  step={1}
                  stepPixelSize={15}
                  minValue={0}
                  maxValue={7}
                  value={crew_share * 100}
                  onDrag={(value) =>
                    act('adjustshare', {
                      adjust: value,
                    })
                  }
                />
              </LabeledList.Item>
              <LabeledList.Item label="Total Profit Shared">
                {crew_share * 100 * crew.length}%
              </LabeledList.Item>
            </LabeledList>
          </Table>
        )}
        {tab === 3 && (
          <>
            {cooldown > 0 && (
              <div className="NoticeBox">
                {'On Cooldown: ' + cooldown / 10 + 's'}
              </div>
            )}
            <Table>
              <Table.Row header>
                <Table.Cell>Job Name</Table.Cell>
                <Table.Cell>Slots</Table.Cell>
              </Table.Row>
              {jobs.map((job: JobData) => (
                <Table.Row key={job.name}>
                  <Table.Cell>{job.name}</Table.Cell>
                  <Table.Cell>
                    <Button
                      content="+"
                      disabled={
                        !(isAdmin || jobIncreaseAllowed[job.name]) ||
                        cooldown > 0 ||
                        job.slots >= job.max
                      }
                      tooltip={
                        !jobIncreaseAllowed[job.name] && !isAdmin
                          ? 'Cannot increase job slots above maximum.'
                          : undefined
                      }
                      color={job.slots >= job.def ? 'average' : 'default'}
                      onClick={() =>
                        act('adjustJobSlot', {
                          toAdjust: job.ref,
                          delta: 1,
                        })
                      }
                    />
                    {job.slots}
                    <Button
                      content="-"
                      disabled={cooldown > 0 || job.slots <= 0}
                      onClick={() =>
                        act('adjustJobSlot', {
                          toAdjust: job.ref,
                          delta: -1,
                        })
                      }
                    />
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          </>
        )}
      </Section>
    </div>
  );
};

const ApplicationCard = ({ app, act }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending':
        return '#ffaa00';
      case 'accepted':
        return '#00ff00';
      case 'denied':
        return '#ff0000';
      default:
        return '#cccccc';
    }
  };

  const getQuirkColor = (color: string) => {
    switch (color) {
      case 'good':
        return '#aaffaa';
      case 'bad':
        return '#ffaaaa';
      case 'neutral':
        return '#aaaaff';
      default:
        return '#cccccc';
    }
  };

  const getGenderDisplay = (gender: string) => {
    switch (gender?.toLowerCase()) {
      case 'male':
        return 'Мужской';
      case 'female':
        return 'Женский';
      default:
        return 'Фембой';
    }
  };

  return (
    <Box className="application-card">
      <Flex>
        <Flex.Item className="character-info">
          <div className="character-header">
            <div className="character-name">
              <div className="name">{app.name}</div>
              <div className="ckey">CKey: {app.key}</div>
            </div>
            <div className="status-badges">
              <div className={`status-badge ${app.status}`}>{app.status}</div>
              {app.status === 'accepted' && app.character_valid === false && (
                <div className="status-badge invalid-character">
                  Персонаж изменён
                </div>
              )}
            </div>
          </div>

          <div className="character-details">
            {(app.character_age ||
              app.character_species ||
              app.character_gender) && (
              <div className="detail-row">
                {app.character_age && (
                  <span className="age">Возраст: {app.character_age}</span>
                )}
                {app.character_species && (
                  <span className="species">Раса: {app.character_species}</span>
                )}
                {app.character_gender && (
                  <span className="gender">
                    Пол: {getGenderDisplay(app.character_gender)}
                  </span>
                )}
              </div>
            )}

            {app.target_job && (
              <div className="detail-row">
                <span className="target-job">
                  Желаемая должность: {app.target_job}
                </span>
              </div>
            )}

            {app.character_quirks &&
              Array.isArray(app.character_quirks) &&
              app.character_quirks.length > 0 && (
                <div className="quirks-section">
                  <div className="quirks-label">Черты характера:</div>
                  <div className="quirks-list">
                    {app.character_quirks.map(
                      (quirk: QuirkData, index: number) => (
                        <span
                          key={index}
                          className={`quirk-badge ${quirk.color}`}
                          title={quirk.desc}
                        >
                          {quirk.name} ({quirk.value > 0 ? '+' : ''}
                          {quirk.value})
                        </span>
                      ),
                    )}
                  </div>
                </div>
              )}

            <div className="message-section">
              <div className="message-label">Сообщение:</div>
              <div className="message-text">
                {app.text || 'Сообщение отсутствует'}
              </div>
            </div>

            {app.denial_reason && (
              <div className="message-section">
                <div className="message-label" style={{ color: '#ffaaaa' }}>
                  Причина отказа:
                </div>
                <div
                  className="message-text"
                  style={{ borderColor: '#ff4444' }}
                >
                  {app.denial_reason}
                </div>
              </div>
            )}
          </div>

          <div className="action-buttons">
            {app.status === 'pending' ? (
              <>
                <Button
                  content="Принять"
                  color="good"
                  icon="check"
                  onClick={() =>
                    act('setApplication', {
                      ref: app.ref,
                      newStatus: 'yes',
                    })
                  }
                />
                <Button
                  content="Отклонить"
                  color="bad"
                  icon="times"
                  onClick={() =>
                    act('denyWithReason', {
                      ref: app.ref,
                    })
                  }
                />
              </>
            ) : (
              <Button
                content="Удалить заявку"
                color="black"
                icon="trash"
                onClick={() =>
                  act('removeApplication', {
                    ref: app.ref,
                  })
                }
              />
            )}
          </div>
        </Flex.Item>

        <Flex.Item>
          <div className="character-photo">
            {app.character_photo ? (
              <img
                src={`data:image/png;base64,${app.character_photo}`}
                alt="Character Portrait"
              />
            ) : (
              <div className="no-photo">
                Фото персонажа
                <br />
                недоступно
              </div>
            )}
          </div>
        </Flex.Item>
      </Flex>
    </Box>
  );
};
