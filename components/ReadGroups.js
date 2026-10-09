import { Component } from "@noflo/noflo";

/**
 * Sends the group names surrounding each packet on a `group` port while
 * forwarding every IP. Unlike ReadGroup, it can `strip` brackets from the
 * forwarded stream and only forward group levels up to a `threshold`.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Send the groups surrounding a packet",
    forwardBrackets: {},
    inPorts: {
      in: { datatype: "all", addressable: true },
      strip: {
        datatype: "boolean",
        control: true,
        default: false,
      },
      threshold: {
        datatype: "int",
        control: true,
        default: Number.POSITIVE_INFINITY,
      },
    },
    outPorts: {
      out: { datatype: "all" },
      group: { datatype: "string" },
    },
  });

  /** @type {Map<string, string[]>} */
  const groups = new Map();
  /**
   * @param {string|null} scope
   * @param {number|null} idx
   * @returns {string[]}
   */
  const ensureGroups = (scope, idx) => {
    const key = `${scope ?? "null"}#${idx ?? 0}`;
    let list = groups.get(key);
    if (!list) {
      list = [];
      groups.set(key, list);
    }
    return list;
  };
  c.tearDown = async () => {
    groups.clear();
  };

  c.process((input, output) => {
    const indexesWithIps = /** @type {number[]} */ (
      input.attached("in")
    ).filter((idx) => input.has(["in", idx]));
    if (!indexesWithIps.length) {
      return;
    }
    if (input.attached("strip").length && !input.hasData("strip")) {
      return;
    }
    if (input.attached("threshold").length && !input.hasData("threshold")) {
      return;
    }
    let strip = false;
    if (input.hasData("strip")) {
      // The 1.x component compared the string form against 'true'
      strip = String(input.getData("strip")) === "true";
    }
    let threshold = Number.POSITIVE_INFINITY;
    if (input.hasData("threshold")) {
      threshold = Number.parseInt(input.getData("threshold"), 10);
    }
    for (const idx of indexesWithIps) {
      const currentGroups = ensureGroups(input.scope, idx);
      const packet = /** @type {import("@noflo/noflo").IP} */ (
        input.get(["in", idx])
      );
      // The consumed packet carries the source connection index; a
      // non-addressable out port rejects sending it
      packet.index = null;
      if (packet.type === "openBracket") {
        currentGroups.push(packet.data);
        if (currentGroups.length > threshold) {
          output.send({ out: packet });
          continue;
        }
        output.send({ group: packet.data });
        if (strip) {
          continue;
        }
        output.send({ out: packet });
        continue;
      }
      if (packet.type === "data") {
        output.send({ out: packet });
        continue;
      }
      if (packet.type === "closeBracket") {
        if (currentGroups.length > threshold || !strip) {
          output.send({ out: packet });
        }
        currentGroups.pop();
      }
    }
    output.done();
  });

  return c;
}
