import { useBackend } from '../backend';
import { Section } from '../components';
import { Window } from '../layouts';
import { FactionButtons } from './FactionButtons';

export const ShipFactionSelect = (props, context) => {
  const { act } = useBackend(context);

  return (
    <Window title="Меню выбора фракций" width={700} height={420} resizable>
      <Window.Content>
        <Section>
          <FactionButtons showCloseButton />
        </Section>
      </Window.Content>
    </Window>
  );
};
