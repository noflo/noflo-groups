import { Component, IP } from "@noflo/noflo";

/**
 * Surround data IPs with brackets named from the `group` control port.
 * A colon-separated `group` string produces nested brackets; an array
 * produces one bracket per member.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Surround data IPs with brackets",
    forwardBrackets: {},
    inPorts: {
      in: {
        datatype: "all",
        description: "IPs to forward",
        required: true,
      },
      group: {
        datatype: "string",
        description: "Groups to encapsulate incoming packets into",
        control: true,
        required: true,
      },
    },
    outPorts: {
      out: {
        datatype: "all",
        description: "Forwarded IPs with encapsulating brackets",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("in", "group")) {
      return;
    }
    const [data, group] = input.getData("in", "group");
    /** @type {unknown[]} */
    const brackets = Array.isArray(group) ? group.slice(0) : group.split(":");
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
