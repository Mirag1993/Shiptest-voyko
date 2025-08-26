import { useBackend } from "../backend";
import { Button } from "../components";
import { Section } from "../components";
import { Window } from "../layouts";

export const CompactNuclearReactor = (props, context) => {
	const { act, data } = useBackend(context);

	return (
		<Window width={800} height={600} title="Compact Nuclear Reactor">
			<Window.Content scrollable>
				<Section title="Reactor Status">
					<div>State: {data.state || "OFF"}</div>
					<div>Power Output: {data.power_output || "0"} kW</div>
					<div>Core Temperature: {data.core_T || "300"}K</div>
					<div>Gel Temperature: {data.gel_T || "300"}K</div>
					<div>
						Emergency Status: {data.emergency_status || "normal"}
					</div>
					<div>
						GEL BUS: {data.has_bus ? "Connected" : "Disconnected"}
					</div>
				</Section>

				<Section title="Reactor Control">
					<Button
						content="START"
						color="green"
						disabled={data.state !== 0}
						onClick={() => act("start")}
					/>
					<Button
						content="STOP"
						color="orange"
						disabled={data.state === 0}
						onClick={() => act("stop")}
					/>
					<Button
						content="SCRAM"
						color="red"
						disabled={data.state === 0}
						onClick={() => act("scram")}
					/>
				</Section>
			</Window.Content>
		</Window>
	);
};
