import { Component, IP } from "@noflo/noflo";

/**
 * Flattens the group tree of each connection to a single level: the
 * first data IP opens one bracket joining all enclosing group names,
 * closed when the enclosing levels end. Brackets arriving after data was
 * sent are ignored.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Flatten group tree to a single level",
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
   * @typedef {Object} DepthState
   * @property {string[]} groups
   * @property {string[]} dataGroups
   */

  /** @type {Map<string, DepthState>} */
  const depth = new Map();
  /**
   * @param {string|null} scope
   * @param {number|null} idx
   * @returns {DepthState}
   */
  const ensureDepth = (scope, idx) => {
    const key = `${scope ?? "null"}#${idx ?? 0}`;
    let state = depth.get(key);
    if (!state) {
      state = { groups: [], dataGroups: [] };
      depth.set(key, state);
    }
    return state;
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
      const state = ensureDepth(input.scope, idx);
      const packet = /** @type {import("@noflo/noflo").IP} */ (
        input.get(["in", idx])
      );
      // The consumed packet carries the source connection index; a
      // non-addressable out port rejects sending it
      packet.index = null;
      if (packet.type === "openBracket") {
        state.groups.push(packet.data);
        continue;
      }
      if (packet.type === "data") {
        if (state.groups.length && !state.dataGroups.length) {
          state.dataGroups = state.groups.slice(0);
          output.send({
            out: new IP("openBracket", state.dataGroups.join(":")),
          });
        }
        output.send({ out: packet });
        continue;
      }
      if (packet.type === "closeBracket") {
        if (state.groups.join(":") === state.dataGroups.join(":")) {
          output.send({
            out: new IP("closeBracket", state.dataGroups.join(":")),
          });
          state.dataGroups = [];
        }
        state.groups.pop();
      }
    }
    output.done();
  });

  return c;
}
