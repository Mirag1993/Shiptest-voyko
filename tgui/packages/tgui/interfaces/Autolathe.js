import {
  Box,
  Button,
  Collapsible,
  Dimmer,
  Flex,
  Icon,
  Input,
  LabeledList,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { capitalize, createSearch } from 'tgui-core/string';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { useState } from 'react';

const MAX_SEARCH_RESULTS = 25;

export const Autolathe = (props) => {
  const { act, data } = useBackend();
  // Extract `health` and `color` variables from the `data` object.
  const {
    materialtotal,
    materialsmax,
    materials = [],
    categories = [],
    all_designs = [],
    hasDisk,
    active,
  } = data;
  const [current_category, setCategory] = useState(categories[0] || 'None');
  const [searchText, setSearchText] = useState('');
  const [inputKey, setInputKey] = useState(0);
  const filteredmaterials = materials.filter(
    (material) => material.mineral_amount > 0,
  );

  // Client-side search and filtering
  const testSearch = createSearch(searchText, (design) => design.name);
  const designs =
    (searchText.length > 0 &&
      all_designs.filter(testSearch).slice(0, MAX_SEARCH_RESULTS)) ||
    (current_category !== 'None' &&
      all_designs.filter((design) =>
        design.categories?.includes(current_category),
      )) ||
    [];
  return (
    <Window title="Autolathe" theme="ntos_terminal" width={600} height={700}>
      <Window.Content scrollable>
        <Section
          title="Total Materials"
          buttons={
            <Button
              icon="eject"
              content="Eject design disk"
              disabled={!hasDisk}
              onClick={() => {
                act('diskEject');
              }}
            />
          }
        >
          <LabeledList>
            <LabeledList.Item label="Total Materials">
              <ProgressBar
                value={materialtotal}
                minValue={0}
                maxValue={materialsmax}
                ranges={{
                  good: [materialsmax * 0.85, materialsmax],
                  average: [materialsmax * 0.25, materialsmax * 0.85],
                  bad: [0, materialsmax * 0.25],
                }}
              >
                {materialtotal + '/' + materialsmax + ' cm³'}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item>
              {filteredmaterials.length > 0 && (
                <Collapsible title="Materials">
                  <LabeledList>
                    {filteredmaterials.map((material) => (
                      <MaterialRow
                        key={material.id}
                        material={material}
                        materialsmax={materialsmax}
                        onRelease={(amount) =>
                          act('materialEject', {
                            materialName: material.name,
                            amount: amount,
                          })
                        }
                      />
                    ))}
                  </LabeledList>
                </Collapsible>
              )}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section
          title="Search"
          buttons={
            <Button
              icon="times"
              content="Clear"
              disabled={!searchText}
              onClick={() => {
                setSearchText('');
                setCategory(categories[0] || 'None');
                setInputKey((k) => k + 1); // Force remount
              }}
            />
          }
        >
          <Input
            key={inputKey}
            fluid
            placeholder="Search Recipes..."
            value={searchText}
            onInput={(_, value) => {
              setSearchText(value);
              if (!value.length) {
                setCategory(categories[0] || 'None');
              }
            }}
          />
        </Section>
        <Section title="Categories">
          <Box>
            {categories.map((category) => (
              // eslint-disable-next-line react/jsx-key
              <Button
                selected={current_category === category}
                content={category}
                onClick={() => {
                  setCategory(category);
                  setSearchText('');
                }}
              />
            ))}
          </Box>
        </Section>
        {(searchText.length > 0 || current_category !== 'None') && (
          <Section
            title={
              searchText.length > 0
                ? 'Search results for "' + searchText + '"'
                : 'Displaying ' + current_category
            }
            buttons={
              <Button
                icon="times"
                content="Close Category"
                onClick={() => {
                  setCategory('None');
                  setSearchText('');
                }}
              />
            }
          >
            {active === 1 && (
              <Dimmer fontSize="32px">
                <Icon name="cog" spin />
                {'Building items...'}
              </Dimmer>
            )}
            <Flex direction="row" wrap="nowrap">
              <Table>
                {(designs.length &&
                  designs.map((design) => (
                    <Table.Row key={design.id}>
                      <Flex.Item>
                        <Button
                          content={design.name}
                          disabled={design.buildable}
                          onClick={() =>
                            act('make', {
                              id: design.id,
                              multiplier: '1',
                            })
                          }
                        />
                      </Flex.Item>
                      {design.sheet ? (
                        <Table.Cell>
                          <Flex.Item grow={1}>
                            <Button
                              icon="hammer"
                              content="15"
                              disabled={!design.mult15}
                              onClick={() =>
                                act('make', {
                                  id: design.id,
                                  multiplier: '15',
                                })
                              }
                            />
                            <Button
                              icon="hammer"
                              content="30"
                              disabled={!design.mult30}
                              onClick={() =>
                                act('make', {
                                  id: design.id,
                                  multiplier: '30',
                                })
                              }
                            />
                          </Flex.Item>
                        </Table.Cell>
                      ) : (
                        <Table.Cell>
                          <Flex.Item grow={3}>
                            <Button
                              icon="hammer"
                              content="5"
                              disabled={!design.mult5}
                              onClick={() =>
                                act('make', {
                                  id: design.id,
                                  multiplier: '5',
                                })
                              }
                            />
                            <Button
                              icon="hammer"
                              content="10"
                              disabled={!design.mult10}
                              onClick={() =>
                                act('make', {
                                  id: design.id,
                                  multiplier: '10',
                                })
                              }
                            />
                          </Flex.Item>
                        </Table.Cell>
                      )}
                      <Table.Cell>
                        <Button.Input
                          content={'[Max:' + design.maxmult + ']'}
                          maxValue={design.maxmult}
                          disabled={design.buildable}
                          backgroundColor={
                            design.buildable ? '#00000000' : 'default'
                          }
                          onCommit={(e, value) =>
                            act('make', {
                              id: design.id,
                              multiplier: value,
                            })
                          }
                        />
                      </Table.Cell>
                      {design.cost}
                    </Table.Row>
                  ))) || (
                  <Table.Row>
                    <Table.Cell>{'No designs found.'}</Table.Cell>
                  </Table.Row>
                )}
              </Table>
            </Flex>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};

const MaterialRow = (props) => {
  const { material, materialsmax, onRelease } = props;

  const [amount, setAmount] = useSharedState(
    'autolathe_amount_' + material.name,
    1,
  );

  const amountAvailable = Math.floor(material.amount);
  return (
    <LabeledList.Item key={material.id}>
      <Table width="100%">
        <Table.Row>
          <Table.Cell>{capitalize(material.name)}</Table.Cell>
          <Table.Cell textAlign="right">
            <Box mr={2} color="label" inline>
              {material.sheets_amount} sheets
            </Box>
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            <Button
              disabled={material.sheets_amount < 1}
              content="x1"
              onClick={() => onRelease(1)}
            />
            <Button
              disabled={material.sheets_amount < 5}
              content="x5"
              onClick={() => onRelease(5)}
            />
            <Button
              disabled={material.sheets_amount < 10}
              content="x10"
              onClick={() => onRelease(10)}
            />
            <Button
              disabled={material.sheets_amount < 25}
              content="x25"
              onClick={() => onRelease(25)}
            />
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            <NumberInput
              width="32px"
              step={1}
              stepPixelSize={5}
              minValue={1}
              maxValue={material.sheets_amount}
              value={amount}
              onChange={(value) => setAmount(value)}
            />
            <Button
              disabled={material.sheets_amount < 1}
              content="Release"
              onClick={() => onRelease(amount)}
            />
          </Table.Cell>
        </Table.Row>
        <Table.Row>
          <Table.Cell colspan="4">
            <ProgressBar
              style={{
                transform: 'scaleX(-1) scaleY(1)',
              }}
              value={materialsmax - material.mineral_amount}
              maxValue={materialsmax}
              color="black"
              backgroundColor={material.matcolour}
            >
              <div style={{ transform: 'scaleX(-1)' }}>
                {material.mineral_amount + ' cm³'}
              </div>
            </ProgressBar>
          </Table.Cell>
        </Table.Row>
      </Table>
    </LabeledList.Item>
  );
};
