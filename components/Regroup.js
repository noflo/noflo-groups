import { Component, IP } from "@noflo/noflo";

/**
 * Forwards all data IPs, strips incoming groups, and replaces them with
 * the group names accumulated on the `group` port (each `group` data IP
 * adds one level, kept for subsequent packets until shutdown).
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "Forward all the data IPs, strip all groups, and replace them with groups from another connection",
    forwardBrackets: {},
    inPorts: {
      in: { datatype: "all", required: true },
      group: { datatype: "string" },
    },
    outPorts: {
      out: { datatype: "all" },
    },
  });

  /** @type {Map<string, string[]>} */
  const groupMap = new Map();
  c.tearDown = async () => {
    groupMap.clear();
  };

  c.process((input, output) => {
    if (input.hasData("group")) {
      const key = input.scope ?? "null";
      let stored = groupMap.get(key);
      if (!stored) {
        stored = [];
        groupMap.set(key, stored);
      }
      stored.push(input.getData("group"));
      output.done();
      return;
    }
    if (!input.hasData("in")) {
      return;
    }
    const key = input.scope ?? "null";
    const stored = groupMap.get(key);
    const groups = stored ? stored.slice(0) : [];
    const data = input.getData("in");
    for (const group of groups) {
      output.send({ out: new IP("openBracket", group) });
    }
    output.send({ out: data });
    for (const group of groups.slice().reverse()) {
      output.send({ out: new IP("closeBracket", group) });
    }
    output.done();
  });

  return c;
}
