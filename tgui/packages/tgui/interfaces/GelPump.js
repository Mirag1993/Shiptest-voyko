import { useBackend, useSharedState } from '../backend';
import { Button } from '../components';
import { Section } from '../components';
import { Window } from '../layouts';
import { ProgressBar } from '../components';

// Безопасное форматирование чисел под старые движки (Trident/MSHTML):
const safeFixed = (v, d = 1, fallback = '0.0') => {
  // Нормализуем вход
  let n = v === null || v === undefined || v === '' ? NaN : +v;
  if (!isFinite(n)) n = 0;
  // Пытаемся обычное toFixed (быстро)
  try {
    return n.toFixed(d);
  } catch (e) {
    // Запасной путь: ручное округление и добивка нулей
    const p = Math.pow(10, d);
    const r = Math.round(n * p) / p;
    let s = String(r);
    if (d <= 0) return s;
    const parts = s.split('.');
    const frac = (parts[1] || '').padEnd(d, '0');
    return `${parts[0]}.${frac}`;
  }
};

export const GelPump = (props, context) => {
  const { act, data = {} } = useBackend(context);
  const [selectedTab, setSelectedTab] = useSharedState(
    context,
    'selectedTab',
    'status'
  );

  return (
    <Window width={600} height={400} title="Gel Circulation Pump">
      <Window.Content scrollable>
        {/* Tab Navigation */}
        <div style={{ marginBottom: '10px' }}>
          <Button
            content="Status"
            selected={selectedTab === 'status'}
            onClick={() => setSelectedTab('status')}
          />
          <Button
            content="Control"
            selected={selectedTab === 'control'}
            onClick={() => setSelectedTab('control')}
          />
        </div>

        {/* Status Tab */}
        {selectedTab === 'status' && (
          <Section title="Pump Status">
            <div>
              Status:{' '}
              <span
                style={{
                  color: data.active ? '#00ff00' : '#ff0000',
                }}
              >
                {data.active ? 'ACTIVE' : 'INACTIVE'}
              </span>
            </div>
            <div>Flow Rate: {safeFixed(data.flow_rate, 1)} L/min</div>
            <div>Power Usage: {safeFixed(data.power_usage, 0)} W</div>
            <div>
              Efficiency: {Math.round(Number(data.efficiency || 1) * 100)}%
            </div>
            <div>
              Pump Gel: {safeFixed(data.gel_volume || 0, 1)} /{' '}
              {safeFixed(data.gel_capacity || 100, 0)} L
            </div>
            <div>
              Network Gel: {safeFixed(data.network_gel_volume || 0, 1)} /{' '}
              {safeFixed(data.network_gel_capacity || 0, 0)} L
            </div>
            <div>
              Gel Cell:{' '}
              {data.has_gel_cell
                ? `${safeFixed(data.gel_cell_level || 0, 0)}%`
                : 'None'}
            </div>
            <div>
              Connection:{' '}
              <span
                style={{
                  color: data.connected ? '#00ff00' : '#ff0000',
                }}
              >
                {data.connected ? 'Connected' : 'Disconnected'}
              </span>
            </div>
          </Section>
        )}

        {/* Control Tab */}
        {selectedTab === 'control' && (
          <>
            <Section title="Pump Control">
              <Button
                content={data.active ? 'STOP' : 'START'}
                color={data.active ? 'red' : 'green'}
                onClick={() => act('toggle')}
              />
            </Section>

            <Section title="Power Control">
              <div>
                Pump Power: {safeFixed(data.pump_power, 0)} /{' '}
                {safeFixed(data.max_pump_power ?? 100, 0)}
              </div>
              <ProgressBar
                value={Number(data.pump_power || 0)}
                maxValue={Number(data.max_pump_power || 100)}
                color="blue"
              />
              <div style={{ marginTop: '10px' }}>
                <Button
                  content="Increase"
                  onClick={() =>
                    act('set_power', {
                      value: Math.min(
                        (data.pump_power || 0) + 10,
                        data.max_pump_power || 100
                      ),
                    })
                  }
                />
                <Button
                  content="Decrease"
                  onClick={() =>
                    act('set_power', {
                      value: Math.max((data.pump_power || 0) - 10, 0),
                    })
                  }
                />
              </div>
            </Section>

            <Section title="Power Level Control">
              <div>
                Current Level:{' '}
                <span style={{ color: '#00ff00' }}>
                  {data.pump_power_level || 'MEDIUM'}
                </span>
              </div>
              <div style={{ marginTop: '10px' }}>
                <Button
                  content="OFF"
                  selected={data.pump_power_level === 'OFF'}
                  onClick={() => act('set_power_level', { level: 'OFF' })}
                />
                <Button
                  content="LOW"
                  selected={data.pump_power_level === 'LOW'}
                  onClick={() => act('set_power_level', { level: 'LOW' })}
                />
                <Button
                  content="MEDIUM"
                  selected={data.pump_power_level === 'MEDIUM'}
                  onClick={() => act('set_power_level', { level: 'MEDIUM' })}
                />
                <Button
                  content="HIGH"
                  selected={data.pump_power_level === 'HIGH'}
                  onClick={() => act('set_power_level', { level: 'HIGH' })}
                />
              </div>
            </Section>
          </>
        )}
      </Window.Content>
    </Window>
  );
};
