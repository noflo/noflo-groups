import { Component } from "@noflo/noflo";

/**
 * Sends the group names surrounding each packet on a `group` port while
 * forwarding every IP (including brackets) unchanged. Group state is
 * tracked per connection index and scope.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Send the groups surrounding a packet",
    forwardBrackets: {},
    inPorts: {
      in: { datatype: "all", addressable: true },
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
        output.send({ out: packet, group: packet.clone() });
        continue;
      }
      if (packet.type === "data") {
        output.send({ group: currentGroups.join(":") });
        output.send({ out: packet });
        continue;
      }
      if (packet.type === "closeBracket") {
        currentGroups.pop();
        output.send({ out: packet, group: packet.clone() });
      }
    }
    output.done();
  });

  return c;
}
