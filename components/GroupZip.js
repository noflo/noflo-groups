import { Component, IP } from "@noflo/noflo";

/**
 * Wraps each incoming data IP into a bracket named by the `group` port
 * value, pairing data and group packets by order received.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Group packets by a group in order received",
    forwardBrackets: {},
    inPorts: {
      in: { datatype: "all", required: true },
      group: { datatype: "string", required: true },
    },
    outPorts: {
      out: { datatype: "all" },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("in", "group")) {
      return;
    }
    const [data, group] = input.getData("in", "group");
    output.send({ out: new IP("openBracket", group) });
    output.send({ out: data });
    output.send({ out: new IP("closeBracket", group) });
    output.done();
  });

  return c;
}
