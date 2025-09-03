import { useState } from 'react';
import {
  Box,
  Button,
  Flex,
  Icon,
  Input,
  Section,
  Stack,
  Table,
  Tabs,
  Tooltip,
} from 'tgui-core/components';

import { useBackend } from '../../../backend';

export const CargoCatalog = (props, context) => {
  const { act, data } = useBackend();

  const { self_paid, app_cost } = data as any;
  const supplies = Object.values((data as any)?.supplies || {});

  const [activeSupplyName, setActiveSupplyName] = useState(
    (supplies[0] as any)?.name || '',
  );

  const [searchText, setSearchText] = useState('');

  const activeSupply =
    activeSupplyName === 'search_results'
      ? { packs: searchForSupplies(supplies, searchText) }
      : supplies.find((supply: any) => supply.name === activeSupplyName) ||
        supplies[0];

  if (!supplies || supplies.length === 0) {
    return (
      <Section title="Catalog">
        <Box textAlign="center" color="label">
          No supplies available.
        </Box>
      </Section>
    );
  }

  return (
    <Section title="Catalog">
      <Flex>
        <Flex.Item ml={-1} mr={1}>
          <Tabs vertical>
            <Tabs.Tab
              key="search_results"
              selected={activeSupplyName === 'search_results'}
            >
              <Stack align="baseline">
                <Stack.Item>
                  <Icon name="search" />
                </Stack.Item>
                <Stack.Item grow>
                  <Input
                    fluid
                    placeholder="Search..."
                    value={searchText}
                    onInput={(e: any, value: string) => {
                      if (value === searchText) {
                        return;
                      }

                      if (value.length) {
                        setActiveSupplyName('search_results');
                      } else if (activeSupplyName === 'search_results') {
                        setActiveSupplyName((supplies[0] as any)?.name || '');
                      }
                      setSearchText(value);
                    }}
                  />
                </Stack.Item>
              </Stack>
            </Tabs.Tab>
            {supplies.map((supply: any) => (
              <Tabs.Tab
                key={supply.name}
                selected={supply.name === activeSupplyName}
                onClick={() => {
                  setActiveSupplyName(supply.name);
                  setSearchText('');
                }}
              >
                {supply.name} ({supply.packs.length})
              </Tabs.Tab>
            ))}
          </Tabs>
        </Flex.Item>
        <Flex.Item grow={1} basis={0}>
          <Table>
            {(activeSupply as any)?.packs?.map((pack: any) => {
              return (
                <Table.Row key={pack.name} className="candystripe">
                  <Table.Cell>{pack.name}</Table.Cell>
                  <Table.Cell collapsing textAlign="center">
                    <Tooltip content={pack.desc} position="left">
                      <Icon name="question" size={1} />
                    </Tooltip>
                  </Table.Cell>
                  <Table.Cell collapsing textAlign="right">
                    <Button
                      fluid
                      onClick={() =>
                        act('add', {
                          id: pack.id,
                        })
                      }
                    >
                      {formatMoney(
                        self_paid && app_cost
                          ? Math.round(pack.cost * 1.1)
                          : pack.cost,
                      )}
                      {' cr'}
                    </Button>
                  </Table.Cell>
                </Table.Row>
              );
            })}
          </Table>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const searchForSupplies = (supplies: any[], searchText: string) => {
  if (!searchText) return [];

  const results: any[] = [];
  for (const supply of supplies) {
    for (const pack of supply.packs || []) {
      if (
        pack.name.toLowerCase().includes(searchText.toLowerCase()) ||
        pack.desc.toLowerCase().includes(searchText.toLowerCase())
      ) {
        results.push(pack);
      }
    }
  }
  return results;
};

const formatMoney = (amount: number) => {
  return amount.toLocaleString();
};
