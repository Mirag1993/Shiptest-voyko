import { useBackend } from '../backend';
import { Box, Button, Section } from '../components';
import { Window } from '../layouts';

export const VendingArmEntry = (props, context) => {
  const { act } = useBackend(context);

  return (
    <Window title="Vending Machine Arm" width={450} height={600} resizable>
      <Window.Content>
        <Section>
          <Box textAlign="center">
            <Button fluid onClick={() => act('enter')}>
              Войти
            </Button>
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};
