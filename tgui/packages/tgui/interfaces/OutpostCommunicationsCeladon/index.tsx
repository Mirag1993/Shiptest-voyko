import { Window } from 'tgui/layouts';
import { Button, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { CargoCatalog } from './Catalog';
import { Data } from './types';

export const OutpostCommunicationsCeladon = (props) => {
  const { act, data } = useBackend<Data>();
  const { points, faction_theme } = data;
  return (
    <Window theme={faction_theme} width={600} height={700}>
      <Window.Content scrollable>
        <Section
          title={Math.round(points) + ' credits'}
          buttons={
            <Stack textAlign="center">
              <Stack.Item>
                <Button.Input
                  content="Withdraw Cash"
                  currentValue={'100'}
                  defaultValue={'100'}
                  onCommit={(e, value) => {
                    const inputValue = parseInt(value, 10) || 0;
                    const maxAmount = points || 0;
                    const finalAmount =
                      inputValue > maxAmount ? maxAmount : inputValue;
                    act('withdrawCash', {
                      value: finalAmount.toString(),
                    });
                  }}
                />
              </Stack.Item>
            </Stack>
          }
        />
        <CargoExpressContent />
      </Window.Content>
    </Window>
  );
};

const CargoExpressContent = (props) => {
  const { act, data } = useBackend<Data>();
  const { message } = data;
  return (
    <>
      <Section title="Cargo Express">
        <LabeledList>
          <LabeledList.Item label="Notice">{message}</LabeledList.Item>
        </LabeledList>
      </Section>
      <CargoCatalog />
    </>
  );
};
