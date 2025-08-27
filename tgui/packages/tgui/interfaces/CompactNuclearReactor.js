import { useBackend, useSharedState } from '../backend';
import { Button } from '../components';
import { Section } from '../components';
import { Window } from '../layouts';

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

export const CompactNuclearReactor = (props, context) => {
  const { act, data = {} } = useBackend(context);

  // Унифицируем состояние: считаем "выключен", если 0/"OFF"/null/undefined.
  const isOff =
    data.state === 0 ||
    data.state === 'OFF' ||
    data.state === null ||
    data.state === undefined;
  const throttle = Math.max(0, Math.min(1, Number(data.throttle) || 0));

  const [selectedTab, setSelectedTab] = useSharedState(
    context,
    'selectedTab',
    'status'
  );

  return (
    <Window width={800} height={600} title="Compact Nuclear Reactor">
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
          <Button
            content="Settings"
            selected={selectedTab === 'settings'}
            onClick={() => setSelectedTab('settings')}
          />
        </div>

        {/* Status Tab */}
        {selectedTab === 'status' && (
          <Section title="Reactor Status">
            <div>State: {isOff ? 'OFF' : 'ON'}</div>
            <div>Power Output: {safeFixed(data.power_output, 1)} kW</div>
            <div>Core Temperature: {safeFixed(data.core_T ?? 27, 1)}°C</div>
            <div>Gel Temperature: {safeFixed(data.gel_T ?? 27, 1)}°C</div>
            <div>Emergency Status: {data.emergency_status || 'normal'}</div>
            <div>Cooling Mode: {data.cooling_mode || 'direct'}</div>
            <div>GEL BUS: {data.has_bus ? 'Connected' : 'Disconnected'}</div>
            {data.bus_issues && data.bus_issues.length > 0 && (
              <div style={{ color: 'orange' }}>
                Issues: {data.bus_issues.join(', ')}
              </div>
            )}
          </Section>
        )}

        {/* Control Tab */}
        {selectedTab === 'control' && (
          <>
            <Section title="Reactor Control">
              <Button
                content="START"
                color="green"
                disabled={!isOff}
                onClick={() => act('start')}
              />
              <Button
                content="STOP"
                color="orange"
                disabled={isOff}
                onClick={() => act('stop')}
              />
              <Button
                content="SCRAM"
                color="red"
                disabled={isOff}
                onClick={() => act('scram')}
              />
            </Section>

            <Section title="Throttle Control">
              <div>Current Throttle: {Math.round(throttle * 100)}%</div>
              <Button
                content="Increase"
                onClick={() =>
                  act('set_throttle', {
                    throttle: Math.min(throttle + 0.1, 1.0),
                  })
                }
              />
              <Button
                content="Decrease"
                onClick={() =>
                  act('set_throttle', {
                    throttle: Math.max(throttle - 0.1, 0.0),
                  })
                }
              />
            </Section>
          </>
        )}

        {/* Settings Tab */}
        {selectedTab === 'settings' && (
          <Section title="Reactor Settings">
            <div>Auto SCRAM: {data.auto_scram ? 'Enabled' : 'Disabled'}</div>
            <div>
              Auto Throttle: {data.auto_throttle ? 'Enabled' : 'Disabled'}
            </div>
            <div>Auto Pump: {data.auto_pump ? 'Enabled' : 'Disabled'}</div>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
