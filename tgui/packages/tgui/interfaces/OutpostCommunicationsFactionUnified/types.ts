// Типы для единого интерфейса фракционных консолей
export type Data = {
  points: number;
  outpostDocked: boolean;
  onShip: boolean;
  numMissions: number;
  maxMissions: number;
  shipMissions: Array<Mission>;
  outpostMissions: Array<Mission>;
  beaconZone: string;
  beaconName: string;
  hasBeacon: boolean;
  usingBeacon: boolean;
  message: string;
  printMsg: string;
  canBuyBeacon: boolean;
  // Фракционные параметры
  faction_theme?: string;
  faction_name?: string;
};

export type Mission = {
  ref: string;
  actStr: string;
  name: string;
  desc: string;
  progressStr: string;
  value: number;
  remaining: number;
  duration: number;
  timeStr: string;
};

export type SupplyCategory = {
  name: string;
  packs: Array<SupplyPack>;
};

export type SupplyPack = {
  name: string;
  cost: number;
  id: string;
  desc: string;
  small_item?: boolean;
  access?: boolean;
  goody?: boolean;
};
