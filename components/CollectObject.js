import { Component } from "@noflo/noflo";

/**
 * Collects packets to an object. Each `collect` connection index maps to
 * a property name from the `keys` control; `allpackets` marks connections
 * whose values are collected into arrays. `release` sends and clears,
 * `clear` discards.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "Collect packets to an object identified by keys organized by connection",
    forwardBrackets: {},
    inPorts: {
      keys: {
        datatype: "string",
        description:
          "Comma-separated property names to be used for data based on connection index",
      },
      allpackets: {
        datatype: "string",
        description:
          "Comma-separated property names to collect all packets for in an array",
      },
      collect: {
        datatype: "all",
        addressable: true,
        description: "Data IPs to collect",
      },
      release: {
        datatype: "bang",
        description: "Release all collected packets as an object",
      },
      clear: {
        datatype: "bang",
        description: "Clear all collected data",
      },
    },
    outPorts: {
      out: { datatype: "object" },
    },
  });

  /**
   * @typedef {Object} CollectContext
   * @property {Record<string, unknown>} data
   * @property {Record<number, string[]>} brackets
   * @property {string[]} keys
   * @property {string[]} allpackets
   */

  /** @type {Map<string, CollectContext>} */
  const contexts = new Map();
  /**
   * @param {string|null} scope
   * @returns {CollectContext}
   */
  const prepareContext = (scope) => {
    const key = scope ?? "null";
    let context = contexts.get(key);
    if (!context) {
      context = { data: {}, brackets: {}, keys: [], allpackets: [] };
      contexts.set(key, context);
    }
    return context;
  };
  c.tearDown = async () => {
    contexts.clear();
  };

  c.process((input, output) => {
    const context = prepareContext(input.scope);
    if (input.hasData("keys")) {
      const keys = input.getData("keys").split(",");
      if (keys.length > 1) {
        // Providing an array clears previous keys
        context.keys = [];
      }
      context.keys = context.keys.concat(keys);
      output.done();
      return;
    }
    if (input.hasData("allpackets")) {
      const keys = input.getData("allpackets").split(",");
      if (keys.length > 1) {
        // Providing an array clears previous keys
        context.allpackets = [];
      }
      context.allpackets = context.allpackets.concat(keys);
      output.done();
      return;
    }
    if (input.hasData("release")) {
      input.getData("release");
      output.send({ out: context.data });
      context.data = {};
      output.done();
      return;
    }
    if (input.hasData("clear")) {
      input.getData("clear");
      contexts.delete(input.scope ?? "null");
      output.done();
      return;
    }
    const indexesWithIps = /** @type {number[]} */ (
      input.attached("collect")
    ).filter((idx) => input.has(["collect", idx]));
    if (!indexesWithIps.length) {
      return;
    }
    // Ensure we have received keys before storing data
    if (input.attached("keys").length && !context.keys.length) {
      return;
    }
    // Ensure we have received allpackets before storing data
    if (input.attached("allpackets").length && !context.allpackets.length) {
      return;
    }
    for (const idx of indexesWithIps) {
      const packet = /** @type {import("@noflo/noflo").IP} */ (
        input.get(["collect", idx])
      );
      // Check that we have a named key for this connection
      if (!context.keys[idx]) {
        continue;
      }

      if (!context.brackets[idx]) {
        context.brackets[idx] = [];
      }
      if (packet.type === "openBracket") {
        context.brackets[idx].push(packet.data);
        continue;
      }
      if (packet.type === "data") {
        const key = context.keys[idx];
        /** @type {Record<string, unknown>} */
        let target = context.data;
        if (context.brackets[idx].length) {
          // First level key is the bracket name, if any
          const groupId = context.brackets[idx][0];
          if (!context.data[groupId]) {
            context.data[groupId] = {};
          }
          target = /** @type {Record<string, unknown>} */ (
            context.data[groupId]
          );
        }
        if (context.allpackets[idx]) {
          // We're collecting all packets for this connection
          if (!target[key]) {
            target[key] = [];
          }
          /** @type {unknown[]} */ (target[key]).push(packet.data);
          continue;
        }
        target[key] = packet.data;
        continue;
      }
      if (packet.type === "closeBracket") {
        context.brackets[idx].pop();
      }
    }
    output.done();
  });

  return c;
}
