import '../../styles/interfaces/AccessList.scss';

import { sortBy } from 'common/collections';
import { Button, Flex, Section, Table, Tabs } from 'tgui-core/components';

import { useSharedState } from '../../backend';

const diffMap = {
  0: {
    icon: 'times-circle',
    color: 'bad',
  },
  1: {
    icon: 'stop-circle',
    color: null,
  },
  2: {
    icon: 'check-circle',
    color: 'good',
  },
};

export const AccessList = (props) => {
  const {
    accesses = [],
    selectedList = [],
    accessMod,
    grantAll,
    denyAll,
    grantDep,
    denyDep,
  } = props;

  // Safe initialization to prevent undefined errors
  const [selectedAccessName, setSelectedAccessName] = useSharedState(
    'accessName',
    accesses[0]?.name,
  );

  const selectedAccess = accesses.find(
    (access) => access.name === selectedAccessName,
  );
  const selectedAccessEntries = sortBy(
    selectedAccess?.accesses || [],
    (entry) => entry.desc,
  );

  const checkAccessIcon = (accesses) => {
    let oneAccess = false;
    let oneInaccess = false;
    for (let element of accesses) {
      if (selectedList.includes(element.ref)) {
        oneAccess = true;
      } else {
        oneInaccess = true;
      }
    }
    if (!oneAccess && oneInaccess) {
      return 0;
    } else if (oneAccess && oneInaccess) {
      return 1;
    } else {
      return 2;
    }
  };

  return (
    <Section
      title="Access"
      buttons={
        <>
          <Button
            icon="check-double"
            content="Grant All"
            color="good"
            onClick={() => grantAll()}
          />
          <Button
            icon="undo"
            content="Deny All"
            color="bad"
            onClick={() => denyAll()}
          />
        </>
      }
    >
      <Flex>
        <Flex.Item className="AccessList__leftColumn">
          <Tabs vertical>
            {accesses.map((access) => {
              const entries = access.accesses || [];
              const icon = diffMap[checkAccessIcon(entries)].icon;
              const color = diffMap[checkAccessIcon(entries)].color;
              return (
                <Tabs.Tab
                  key={access.name}
                  altSelection
                  color={color}
                  icon={icon}
                  selected={access.name === selectedAccessName}
                  onClick={() => setSelectedAccessName(access.name)}
                  className="AccessList__tab"
                >
                  {access.name}
                </Tabs.Tab>
              );
            })}
          </Tabs>
        </Flex.Item>
        <Flex.Item grow={1} className="AccessList__rightColumn">
          <Section
            level={2}
            title={selectedAccess?.name?.[0] || '?'}
            buttons={
              <>
                <Button
                  icon="check"
                  content="Grant Region"
                  color="good"
                  onClick={() => grantDep(selectedAccess.regid)}
                />
                <Button
                  icon="times"
                  content="Deny Region"
                  color="bad"
                  onClick={() => denyDep(selectedAccess.regid)}
                />
              </>
            }
          >
            <Table>
              {selectedAccessEntries.map((entry) => {
                const accessBool = selectedList.includes(entry.ref);
                const diffColor = accessBool ? 'good' : 'bad';
                const diffIcon = accessBool ? 'check' : 'times';
                return (
                  <Table.Row key={entry.ref}>
                    <Table.Cell>
                      <Button
                        fluid
                        icon={diffIcon}
                        content={entry.desc}
                        color={diffColor}
                        onClick={() => accessMod(entry.ref)}
                      />
                    </Table.Cell>
                  </Table.Row>
                );
              })}
            </Table>
          </Section>
        </Flex.Item>
      </Flex>
    </Section>
  );
};
