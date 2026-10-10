import { Component, IP } from "@noflo/noflo";

/**
 * Collects a stream of packets into a simple tree structure. Group levels
 * above the `level` control are forwarded around the collected tree;
 * levels at or below it become object keys.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Collect a stream of packets into a simple tree structure",
    forwardBrackets: {},
    inPorts: {
      in: { datatype: "all", required: true },
      level: {
        datatype: "int",
        default: 0,
        description:
          "Number of brackets (from outermost) to skip collection of",
        control: true,
      },
    },
    outPorts: {
      out: { datatype: "object" },
      error: { datatype: "object" },
    },
  });

  c.process((input, output) => {
    if (!input.hasStream("in")) {
      return;
    }
    if (input.attached("level").length && !input.hasData("level")) {
      return;
    }

    const level = input.hasData("level") ? input.getData("level") : 0;

    const stream = /** @type {import("@noflo/noflo").IP[]} */ (
      input.getStream("in")
    );
    if (stream[0].type === "openBracket" && stream[0].data == null) {
      // Remove the surrounding brackets if they're unnamed
      stream.shift();
      stream.pop();
    }

    /** @type {Record<string, unknown>} */
    const data = {};
    let currentLevel = 0;
    /** @type {string[]} */
    const collectGroups = [];
    /** @type {unknown[]} */
    const forwardGroups = [];

    for (const packet of stream) {
      if (packet.type === "openBracket") {
        if (currentLevel < level) {
          forwardGroups.push(packet.data);
        } else {
          collectGroups.push(packet.data);
        }
        currentLevel += 1;
        continue;
      }
      if (packet.type === "data") {
        if (!collectGroups.length) {
          continue;
        }
        let branch = data;
        for (let idx = 0; idx < collectGroups.length; idx += 1) {
          const bracket = collectGroups[idx];
          if (idx < collectGroups.length - 1) {
            if (!branch[bracket]) {
              branch[bracket] = {};
            }
            branch = /** @type {Record<string, unknown>} */ (branch[bracket]);
            continue;
          }
          if (!branch[bracket]) {
            branch[bracket] = packet.data;
            continue;
          }
          if (!Array.isArray(branch[bracket])) {
            branch[bracket] = [branch[bracket]];
          }
          /** @type {unknown[]} */ (branch[bracket]).push(packet.data);
        }
        continue;
      }
      if (packet.type === "closeBracket") {
        if (currentLevel >= level) {
          collectGroups.pop();
        }
        currentLevel -= 1;
      }
    }

    if (!Object.keys(data).length) {
      output.done(new Error("No tree information was collected"));
      return;
    }

    for (const bracket of forwardGroups) {
      output.send({ out: new IP("openBracket", bracket) });
    }
    output.send({ out: data });
    for (const bracket of forwardGroups.slice().reverse()) {
      output.send({ out: new IP("closeBracket", bracket) });
    }
    output.done();
  });

  return c;
}
