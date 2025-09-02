// Единый файл с re-export'ами для всех фракций
// Все фракции используют единый интерфейс OutpostCommunicationsFactionUnified
// но экспортируются под разными именами для совместимости с DM кодом

export { OutpostCommunicationsFactionUnified as OutpostCommunicationsFactionSolfed } from './OutpostCommunicationsFactionUnified';
export { OutpostCommunicationsFactionUnified as OutpostCommunicationsFactionSyndicate } from './OutpostCommunicationsFactionUnified';
export { OutpostCommunicationsFactionUnified as OutpostCommunicationsFactionInteq } from './OutpostCommunicationsFactionUnified';
export { OutpostCommunicationsFactionUnified as OutpostCommunicationsFactionNanotrasen } from './OutpostCommunicationsFactionUnified';
export { OutpostCommunicationsFactionUnified as OutpostCommunicationsFactionIndependent } from './OutpostCommunicationsFactionUnified';
