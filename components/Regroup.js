import { Component, IP } from "@noflo/noflo";

/**
 * Forwards all data IPs, strips incoming brackets, and replaces them with
 * the bracket names accumulated on the `group` port (each `group` data IP
 * adds one level, kept for subsequent packets until shutdown).
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "Forward all the data IPs, strip all brackets, and replace them with brackets from another connection",
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
    const brackets = stored ? stored.slice(0) : [];
    const data = input.getData("in");
    for (const bracket of brackets) {
      output.send({ out: new IP("openBracket", bracket) });
    }
    output.send({ out: data });
    for (const bracket of brackets.slice().reverse()) {
      output.send({ out: new IP("closeBracket", bracket) });
    }
    output.done();
  });

  return c;
}
