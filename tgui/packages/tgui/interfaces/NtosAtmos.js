import { filter, sortBy } from 'common/collections';
import { LabeledList, ProgressBar, Section } from 'tgui-core/components';
import { toFixed } from 'tgui-core/math';

import { useBackend } from '../backend';
import { getGasColor } from '../constants';
import { NtosWindow } from '../layouts';

export const NtosAtmos = (props) => {
  const { act, data } = useBackend();
  const { AirTemp, AirPressure, AirData } = data;

  // Ensure AirData is always an array to prevent filter() errors
  const safeAirData = Array.isArray(AirData) ? AirData : [];

  // Use direct function calls instead of flow to prevent type errors
  const filteredGases = filter(
    safeAirData,
    (gas) => gas && typeof gas === 'object' && gas.percentage >= 0.01,
  );
  const gases = sortBy(filteredGases, (gas) => -gas.percentage);

  const gasMaxPercentage = Math.max(1, ...gases.map((gas) => gas.percentage));
  return (
    <NtosWindow width={300} height={350}>
      <NtosWindow.Content scrollable>
        <Section>
          <LabeledList>
            <LabeledList.Item label="Temperature">{AirTemp}°C</LabeledList.Item>
            <LabeledList.Item label="Pressure">
              {AirPressure} kPa
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section>
          <LabeledList>
            {gases.map((gas) => (
              <LabeledList.Item key={gas.name} label={gas.name}>
                <ProgressBar
                  color={getGasColor(gas.id)}
                  value={gas.percentage}
                  minValue={0}
                  maxValue={gasMaxPercentage}
                >
                  {toFixed(gas.percentage, 2) + '%'}
                </ProgressBar>
              </LabeledList.Item>
            ))}
          </LabeledList>
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
