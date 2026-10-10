import { Component, IP } from "@noflo/noflo";

/**
 * Forwards the innermost stream content: of each stream, only the
 * outermost bracket level that actually contains data is kept. Empty
 * bracket levels are dropped.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Forward incoming IPs and filter brackets except the last one",
    forwardBrackets: {},
    inPorts: {
      in: {
        datatype: "all",
        description: "IPs to forward",
        addressable: true,
        required: true,
      },
    },
    outPorts: {
      out: { datatype: "all" },
    },
  });

  /**
   * @typedef {Object} DepthLevel
   * @property {string} group
   * @property {boolean} hasData
   */

  /** @type {Map<string, DepthLevel[]>} */
  const depth = new Map();
  /**
   * @param {string|null} scope
   * @param {number|null} idx
   * @returns {DepthLevel[]}
   */
  const ensureDepth = (scope, idx) => {
    const key = `${scope ?? "null"}#${idx ?? 0}`;
    let list = depth.get(key);
    if (!list) {
      list = [];
      depth.set(key, list);
    }
    return list;
  };
  c.tearDown = async () => {
    depth.clear();
  };

  c.process((input, output) => {
    const indexesWithIps = /** @type {number[]} */ (
      input.attached("in")
    ).filter((idx) => input.has(["in", idx]));
    if (!indexesWithIps.length) {
      return;
    }
    for (const idx of indexesWithIps) {
      const levels = ensureDepth(input.scope, idx);
      const packet = /** @type {import("@noflo/noflo").IP} */ (
        input.get(["in", idx])
      );
      // The consumed packet carries the source connection index; a
      // non-addressable out port rejects sending it
      packet.index = null;
      if (packet.type === "openBracket") {
        levels.push({ group: packet.data, hasData: false });
        continue;
      }
      if (packet.type === "data") {
        if (levels.length) {
          const lastLevel = levels[levels.length - 1];
          if (!lastLevel.hasData) {
            output.send({ out: new IP("openBracket", lastLevel.group) });
            lastLevel.hasData = true;
          }
        }
        output.send({ out: packet });
        continue;
      }
      if (packet.type === "closeBracket") {
        const lastLevel = levels.pop();
        if (!lastLevel?.hasData) {
          continue;
        }
        output.send({ out: new IP("closeBracket", lastLevel.group) });
      }
    }
    output.done();
  });

  return c;
}
