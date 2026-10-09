import { Component } from "@noflo/noflo";

/**
 * Uses the first match of the `regexp` control against an incoming group
 * name as the key of an object containing the data. Non-matching groups
 * and their data pass through unchanged.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "specify a regexp string, use the first match as the key of an object containing the data",
    forwardBrackets: {},
    inPorts: {
      in: { datatype: "all", addressable: true, required: true },
      regexp: { datatype: "string", control: true, required: true },
    },
    outPorts: {
      out: { datatype: "all" },
    },
  });

  /** @type {Map<string, string|null>} */
  const matches = new Map();
  /**
   * @param {string|null} scope
   * @param {number|null} idx
   * @returns {string|null}
   */
  const ensureMatches = (scope, idx) => {
    const key = `${scope ?? "null"}#${idx ?? 0}`;
    let value = matches.get(key);
    if (value === undefined) {
      value = null;
      matches.set(key, value);
    }
    return value;
  };
  c.tearDown = async () => {
    matches.clear();
  };

  c.process((input, output) => {
    if (!input.hasData("regexp")) {
      return;
    }
    const indexesWithIps = /** @type {number[]} */ (
      input.attached("in")
    ).filter((idx) => input.has(["in", idx]));
    if (!indexesWithIps.length) {
      return;
    }
    const regexp = new RegExp(input.getData("regexp"));
    for (const idx of indexesWithIps) {
      const key = `${input.scope ?? "null"}#${idx ?? 0}`;
      const match = ensureMatches(input.scope, idx);
      const packet = /** @type {import("@noflo/noflo").IP} */ (
        input.get(["in", idx])
      );
      // The consumed packet carries the source connection index; a
      // non-addressable out port rejects sending it
      packet.index = null;
      if (packet.type === "openBracket") {
        if (typeof packet.data === "string" && packet.data.match(regexp)) {
          matches.set(
            key,
            /** @type {string} */ (packet.data.match(regexp)?.[0]),
          );
        }
        output.send({ out: packet });
        continue;
      }
      if (packet.type === "data") {
        // If there is a match, make an object out of it
        if (match !== null) {
          output.send({ out: { [match]: packet.data } });
          continue;
        }
        output.send({ out: packet });
        continue;
      }
      if (packet.type === "closeBracket") {
        matches.set(key, null);
        output.send({ out: packet });
      }
    }
    output.done();
  });

  return c;
}
