import { Component, IP } from "@noflo/noflo";

/**
 * Forwards incoming IPs and filters brackets except the first (outermost)
 * level: only the outermost bracket of each stream is kept.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "Forward incoming IPs and filter brackets except the first one",
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

  /** @type {Map<string, number>} */
  const depth = new Map();
  /**
   * @param {string|null} scope
   * @param {number|null} idx
   * @returns {number}
   */
  const ensureDepth = (scope, idx) => {
    const key = `${scope ?? "null"}#${idx ?? 0}`;
    let value = depth.get(key);
    if (value === undefined) {
      value = 0;
      depth.set(key, value);
    }
    return value;
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
      const key = `${input.scope ?? "null"}#${idx ?? 0}`;
      const level = ensureDepth(input.scope, idx);
      const packet = /** @type {import("@noflo/noflo").IP} */ (
        input.get(["in", idx])
      );
      // The consumed packet carries the source connection index; a
      // non-addressable out port rejects sending it
      packet.index = null;
      if (packet.type === "openBracket") {
        if (level === 0) {
          output.send({ out: new IP("openBracket", packet.data) });
        }
        depth.set(key, level + 1);
        continue;
      }
      if (packet.type === "data") {
        output.send({ out: packet });
        continue;
      }
      if (packet.type === "closeBracket") {
        depth.set(key, level - 1);
        if (level - 1 === 0) {
          output.send({ out: new IP("closeBracket", packet.data) });
        }
      }
    }
    output.done();
  });

  return c;
}
