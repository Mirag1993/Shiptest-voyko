import { useState } from 'react';
import {
  Button,
  Collapsible,
  Flex,
  Icon,
  Input,
  Section,
  Stack,
  Table,
  Tabs,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';

import { useBackend, useSharedState } from '../../backend';

// DIY: Единая функция валидации данных
const validateData = (data) => ({
  supplies: Array.isArray(data.supplies)
    ? data.supplies
    : Object.values(data.supplies || {}),
  cart: Array.isArray(data.cart) ? data.cart : [],
  self_paid: Boolean(data.self_paid),
  app_cost: Boolean(data.app_cost),
  blockade: Boolean(data.blockade),
});

// KISS: Простая функция поиска без избыточной сложности
const searchForSupplies = (supplies, search, limit = 25) => {
  if (!search?.trim() || !Array.isArray(supplies)) return [];

  const searchLower = search.toLowerCase();

  return supplies
    .flatMap((supply) => supply.packs || [])
    .filter((pack) => pack?.name?.toLowerCase().includes(searchLower))
    .sort((a, b) => a.name.localeCompare(b.name))
    .slice(0, limit);
};

export const CargoCatalog = (props) => {
  const { act, data } = useBackend();
  const validated = validateData(data);
  const { supplies, self_paid, app_cost, blockade } = validated;

  const [activeSupplyName, setActiveSupplyName] = useSharedState(
    'supply',
    supplies[0]?.name,
  );
  const [searchText, setSearchText] = useSharedState('search_text', '');
  const [cart, setCart] = useSharedState('cart', []);
  const [purchasing, setPurchasing] = useState(false);

  // KISS: Получаем константы из сервера, fallback на клиентские значения
  const MAX_CART_ITEMS = data.max_cart_items || 20;
  const SEARCH_RESULTS_LIMIT = data.search_results_limit || 25;

  // KISS: Асинхронная обработка покупки с ожиданием подтверждения сервера
  const handlePurchase = async () => {
    if (purchasing || cart.length === 0 || cart.length > MAX_CART_ITEMS) return;

    setPurchasing(true);
    try {
      // Отправляем запрос и ждем ответа
      const result = await act('purchase', {
        cart: cart,
        total: cartTotal,
      });

      // Очищаем корзину только если покупка была успешной
      // (сервер не вернул ошибку)
      if (result?.success !== false) {
        setCart([]);
      }
    } catch (error) {
      console.error('Purchase failed:', error);
      // При ошибке корзина остается нетронутой
    } finally {
      setPurchasing(false);
    }
  };

  // KISS: Простое вычисление общей стоимости
  const cartTotal = cart.reduce((total, itemId) => {
    const pack = supplies
      .flatMap((s) => s.packs || [])
      .find((p) => p.id === itemId);
    return total + (pack?.discountedcost || pack?.cost || 0);
  }, 0);

  const activeSupply =
    activeSupplyName === 'search_results'
      ? { packs: searchForSupplies(supplies, searchText, SEARCH_RESULTS_LIMIT) }
      : supplies.find((supply) => supply.name === activeSupplyName);

  const removeFromCart = (indexToRemove) => {
    setCart(cart.filter((_, index) => index !== indexToRemove));
  };

  // Простая группировка для отображения
  const groupedCart = cart.reduce((groups, itemId) => {
    if (!groups[itemId]) {
      const pack = supplies
        .flatMap((s) => s.packs || [])
        .find((p) => p.id === itemId);
      groups[itemId] = { pack, count: 0 };
    }
    groups[itemId].count++;
    return groups;
  }, {});

  return (
    <>
      <Section title="Cart">
        <Table.Row>
          <Table.Cell>
            <Button
              icon="times"
              color="transparent"
              content="Clear"
              onClick={() => setCart([])}
            />
            <Button
              color="green"
              content={purchasing ? 'Processing...' : 'Purchase'}
              disabled={
                cart.length === 0 || cart.length > MAX_CART_ITEMS || purchasing
              }
              onClick={handlePurchase}
            />
          </Table.Cell>
          <Table.Cell textAlign="right" collapsing>
            {cart.length === 0 && 'Order is empty'}
            {cart.length > 0 && `Items: ${cart.length}/${MAX_CART_ITEMS}`}
          </Table.Cell>
        </Table.Row>
        {cart.length !== 0 && (
          <Collapsible title="Order Contents">
            <Table>
              {Object.values(groupedCart).map((group, index) => {
                const { pack, count } = group;
                return (
                  <Table.Row key={index} className="candystripe">
                    <Table.Cell>
                      <Button
                        icon="minus"
                        color="transparent"
                        tooltip="Remove one from order"
                        onClick={() => {
                          const itemIndex = cart.findIndex(
                            (id) => id === pack.id,
                          );
                          removeFromCart(itemIndex);
                        }}
                      />
                    </Table.Cell>
                    <Table.Cell>
                      {pack.discountedcost ? pack.discountedcost : pack.cost} cr
                    </Table.Cell>
                    <Table.Cell collapsing color="label" textAlign="right">
                      {pack.name} x{count}
                    </Table.Cell>
                  </Table.Row>
                );
              })}
            </Table>
          </Collapsible>
        )}
        {cartTotal > 0 && (
          <Table.Row>
            <Table.Cell colSpan={2} bold>
              Total: {formatMoney(cartTotal)} cr
            </Table.Cell>
            <Table.Cell textAlign="right" collapsing>
              {cart.length >= 1 && `Contains: ${cart.length} items`}
            </Table.Cell>
          </Table.Row>
        )}
      </Section>
      <Section title="Catalog">
        <Flex>
          <Flex.Item ml={-1} mr={1.5}>
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
                      onInput={(e, value) => {
                        if (value === searchText) return;

                        if (value.length) {
                          setActiveSupplyName('search_results');
                        } else if (activeSupplyName === 'search_results') {
                          setActiveSupplyName(supplies[0]?.name);
                        }
                        setSearchText(value);
                      }}
                    />
                  </Stack.Item>
                </Stack>
              </Tabs.Tab>
              {supplies.map((supply) => (
                <Tabs.Tab
                  key={supply.name}
                  selected={supply.name === activeSupplyName}
                  onClick={() => {
                    setActiveSupplyName(supply.name);
                    setSearchText('');
                  }}
                >
                  {supply.name} ({(supply.packs || []).length})
                </Tabs.Tab>
              ))}
            </Tabs>
          </Flex.Item>
          <Flex.Item grow={1} basis={0}>
            <Table>
              {(activeSupply?.packs || []).map((pack) => {
                const tags = [];
                if (pack.access) {
                  tags.push('Restricted');
                }
                return (
                  <Table.Row key={pack.name} className="candystripe">
                    <Table.Cell>{pack.name}</Table.Cell>
                    <Table.Cell collapsing color="label" textAlign="right">
                      {tags.join(', ')}
                    </Table.Cell>
                    <Table.Cell collapsing textAlign="right">
                      <Button
                        fluid
                        tooltip={pack.desc}
                        color={pack.discountedcost ? 'green' : 'default'}
                        tooltipPosition="left"
                        disabled={cart.length >= MAX_CART_ITEMS}
                        onClick={() => {
                          if (cart.length < MAX_CART_ITEMS) {
                            setCart(cart.concat(pack.id));
                          }
                        }}
                      >
                        {pack.discountedcost
                          ? `(-${pack.discountpercent}%) ${pack.discountedcost}`
                          : formatMoney(
                              (self_paid && !pack.goody) || app_cost
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
    </>
  );
};
