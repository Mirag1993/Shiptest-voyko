import { globalStore } from './backend';
import { IconProvider } from './Icons';
import { useUiScale } from './hooks/useUiScale';

export function App() {
  const { getRoutedComponent } = require('./routes');
  const Component = getRoutedComponent(globalStore);

  // Apply UI Scale through TGUI's built-in scaling system
  useUiScale();

  return (
    <>
      <Component />
      <IconProvider />
    </>
  );
}
