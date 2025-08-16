import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import {
  Button,
  TextArea,
  Stack,
  Section,
  Box,
  Flex,
  Icon,
  Divider,
} from '../components';

export const Application = (props, context) => {
  const { act, data } = useBackend(context);
  const [message, setMessage] = useLocalState(context, 'message', '');
  const [showCkey, setShowCkey] = useLocalState(context, 'showCkey', false);
  const [isSubmitting, setIsSubmitting] = useLocalState(
    context,
    'isSubmitting',
    false
  );
  const [isCancelling, setIsCancelling] = useLocalState(
    context,
    'isCancelling',
    false
  );

  const { ship_name, player_name, job_name } = data;

  // Определяем тип заявки
  const isJobSpecific = !!job_name;
  const applicationTitle = isJobSpecific
    ? `Заявка на должность ${job_name}`
    : `Заявка на вступление в экипаж`;

  // Безопасные обработчики кнопок
  const handleCancel = () => {
    if (isCancelling || isSubmitting) return;
    setIsCancelling(true);

    try {
      act('cancel');
    } catch (error) {
      console.error('Cancel error:', error);
    } finally {
      setTimeout(() => setIsCancelling(false), 2000);
    }
  };

  const handleSubmit = () => {
    if (isSubmitting || isCancelling) return;
    setIsSubmitting(true);

    try {
      // Формируем текст заявки с префиксом профессии
      let finalText = message.trim() || 'Заявка без сообщения';
      
      // Если это заявка на конкретную профессию - добавляем префикс
      if (isJobSpecific && job_name) {
        finalText = `${job_name}: ${finalText}`;
      }
      
      act('submit', {
        text: finalText,
        ckey: showCkey,
      });
    } catch (error) {
      console.error('Submit error:', error);
    } finally {
      setTimeout(() => setIsSubmitting(false), 2000);
    }
  };

  return (
    <Window
      title={`${ship_name} • ${applicationTitle} [v2-MODERN]`}
      width={600}
      height={650}
      resizable
    >
      <Window.Content scrollable>
        <Stack fill vertical gap={1}>
          {/* Заголовок с иконкой */}
          <Stack.Item>
            <Section>
              <Flex align="center" gap={2}>
                <Flex.Item>
                  <Icon
                    name="file-alt"
                    size={2}
                    color="blue"
                    style={{ marginRight: '8px' }}
                  />
                </Flex.Item>
                <Flex.Item grow>
                  <Box>
                    <Box fontSize="18px" bold color="white" mb={1}>
                      {applicationTitle}
                    </Box>
                    <Box fontSize="14px" color="label">
                      {isJobSpecific
                        ? `Корабль: ${ship_name} • Игрок: ${player_name}`
                        : `Подача заявки на корабль ${ship_name} как ${player_name}`}
                    </Box>
                  </Box>
                </Flex.Item>
              </Flex>
            </Section>
          </Stack.Item>

          {/* Информационная панель */}
          <Stack.Item>
            <Section>
              <Box
                style={{
                  background: 'rgba(52, 152, 219, 0.1)',
                  border: '1px solid rgba(52, 152, 219, 0.3)',
                  borderRadius: '8px',
                  padding: '12px',
                }}
              >
                <Flex align="center" gap={1} mb={2}>
                  <Icon name="info-circle" color="blue" />
                  <Box bold color="blue">
                    Информация о заявке
                  </Box>
                </Flex>

                <Box mb={1}>
                  • Данный корабль требует <b>одобрения заявки</b> владельцем
                  для вступления
                </Box>
                <Box mb={1}>
                  • Это <b>OOC утилита</b> для координации между игроками
                </Box>
                {isJobSpecific ? (
                  <Box mb={1}>
                    • Вы подаёте заявку на{' '}
                    <b>конкретную должность: {job_name}</b>
                  </Box>
                ) : (
                  <Box mb={1}>
                    • Заявка на <b>общее вступление</b> в экипаж корабля
                  </Box>
                )}
                <Box>
                  • У вас есть <b>одна заявка на корабль</b>, разные персонажи
                  используют ту же заявку
                </Box>
              </Box>
            </Section>
          </Stack.Item>

          {/* Поле ввода заявки */}
          <Stack.Item grow>
            <Section title="Текст заявки">
              <Box mb={2}>
                <TextArea
                  value={message}
                  fluid
                  height={15}
                  maxLength={1024}
                  placeholder={
                    isJobSpecific
                      ? `Расскажите, почему вы хотите занять должность ${job_name} и что можете предложить экипажу...`
                      : 'Расскажите о себе, своём опыте и почему хотите присоединиться к экипажу...'
                  }
                  onChange={(e, input) => setMessage(input)}
                  style={{
                    fontSize: '14px',
                    lineHeight: '1.4',
                    background: '#1a1a1a',
                    border: '1px solid #444',
                    borderRadius: '6px',
                  }}
                />
                <Box textAlign="right" fontSize="12px" color="label" mt={1}>
                  {message.length}/1024 символов
                </Box>
              </Box>
            </Section>
          </Stack.Item>

          {/* Настройки приватности */}
          <Stack.Item>
            <Section title="Настройки приватности">
              <Box
                style={{
                  background: 'rgba(255, 255, 255, 0.05)',
                  border: '1px solid rgba(255, 255, 255, 0.1)',
                  borderRadius: '6px',
                  padding: '12px',
                }}
              >
                <Flex align="center" gap={1}>
                  <Flex.Item grow>
                    <Box>
                      <Box bold mb={1}>
                        Показать ckey владельцу корабля
                      </Box>
                      <Box fontSize="12px" color="label">
                        Заявки сортируются по ckey, но ваш ckey будет показан
                        владельцу только при включении этой опции
                      </Box>
                    </Box>
                  </Flex.Item>
                  <Flex.Item>
                    <Button.Checkbox
                      content=""
                      checked={showCkey}
                      onClick={() => setShowCkey(!showCkey)}
                      style={{
                        transform: 'scale(1.2)',
                      }}
                    />
                  </Flex.Item>
                </Flex>
              </Box>
            </Section>
          </Stack.Item>

          <Divider />

          {/* Кнопки действий */}
          <Stack.Item>
            <Flex gap={1}>
              <Flex.Item grow>
                <Button
                  content={isCancelling ? 'Отменяется...' : 'Отменить'}
                  color="bad"
                  icon="times"
                  fluid
                  disabled={isCancelling || isSubmitting}
                  onClick={handleCancel}
                  style={{
                    height: '40px',
                    fontSize: '14px',
                  }}
                />
              </Flex.Item>
              <Flex.Item grow>
                <Button
                  content={
                    isSubmitting ? 'Отправляется...' : 'Отправить заявку'
                  }
                  color="good"
                  icon="paper-plane"
                  fluid
                  disabled={isSubmitting || isCancelling}
                  onClick={handleSubmit}
                  style={{
                    height: '40px',
                    fontSize: '14px',
                  }}
                />
              </Flex.Item>
            </Flex>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
