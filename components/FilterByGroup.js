import { Component, IP } from "@noflo/noflo";

/**
 * Filters out brackets that do not match the `regexp` control and their
 * children, forwarding only the content of the matching bracket. Sends an
 * `empty` bang when a top-level stream produced no matching content.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "Given a RegExp string, filter out brackets that do not match and their children data packets/brackets. Forward only the content of the matching bracket.",
    forwardBrackets: {},
    inPorts: {
      in: {
        datatype: "all",
        description: "IPs to filter brackets from",
        addressable: true,
        required: true,
      },
      regexp: {
        datatype: "string",
        description: "Regexp use as a filter for IPs",
        control: true,
        required: true,
      },
    },
    outPorts: {
      out: { datatype: "all" },
      group: { datatype: "string" },
      empty: { datatype: "bang" },
    },
  });

  /**
   * @typedef {Object} FilterScope
   * @property {number} level
   * @property {boolean} hasContent
   * @property {number|null} matchedLevel
   */

  /** @type {Map<string, FilterScope>} */
  const scopes = new Map();
  /**
   * @param {string|null} scopeKey
   * @param {number|null} idx
   * @returns {FilterScope}
   */
  const ensureScope = (scopeKey, idx) => {
    const key = `${scopeKey ?? "null"}#${idx ?? 0}`;
    let state = scopes.get(key);
    if (!state) {
      state = { level: 0, hasContent: false, matchedLevel: null };
      scopes.set(key, state);
    }
    return state;
  };
  c.tearDown = async () => {
    scopes.clear();
  };

  c.process((input, output) => {
    const indexesWithIps = /** @type {number[]} */ (
      input.attached("in")
    ).filter((idx) => input.has(["in", idx]));
    if (!indexesWithIps.length) {
      return;
    }
    if (!input.hasData("regexp")) {
      return;
    }
    const regexp = new RegExp(input.getData("regexp"));
    for (const idx of indexesWithIps) {
      const scope = ensureScope(input.scope, idx);
      const packet = /** @type {import("@noflo/noflo").IP} */ (
        input.get(["in", idx])
      );
      // The consumed packet carries the source connection index; a
      // non-addressable out port rejects sending it
      packet.index = null;
      if (packet.type === "openBracket") {
        if (scope.matchedLevel !== null) {
          output.send({ out: new IP("openBracket", packet.data) });
        }
        scope.level += 1;
        if (
          scope.matchedLevel === null &&
          typeof packet.data === "string" &&
          packet.data.match(regexp)
        ) {
          scope.matchedLevel = scope.level;
          output.send({ group: packet.data });
        }
        continue;
      }
      if (packet.type === "data") {
        if (scope.matchedLevel === null) {
          continue;
        }
        scope.hasContent = true;
        output.send({ out: packet });
        continue;
      }
      if (packet.type === "closeBracket") {
        if (scope.matchedLevel === scope.level) {
          scope.matchedLevel = null;
        }
        if (scope.matchedLevel !== null) {
          output.send({ out: new IP("closeBracket", packet.data) });
        }
        scope.level -= 1;
        if (scope.level) {
          continue;
        }
        if (!scope.hasContent) {
          output.send({ empty: null });
        }
      }
    }
    output.done();
  });

  return c;
}
