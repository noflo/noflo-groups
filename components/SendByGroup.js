import { Component, IP } from "@noflo/noflo";

/**
 * Stores data IPs keyed by their bracket context and releases them when
 * a bang arrives on `in` carrying a matching bracket stream. Data stored
 * after the release request for the same identifier is sent immediately.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      'Send packet held in "data" when receiving matching set of brackets in "in"',
    icon: "share-square",
    forwardBrackets: {},
    inPorts: {
      in: {
        datatype: "bang",
        description:
          "Signal to release IPs associated with the emitted bracket",
        required: true,
      },
      data: {
        datatype: "all",
        description: "IP to store by bracket",
        addressable: true,
      },
    },
    outPorts: {
      out: {
        datatype: "all",
        description: "IP associated with a bracket received on the in port",
      },
    },
  });

  /**
   * @param {unknown[]} brackets
   * @returns {string}
   */
  const getIdentifier = (brackets) =>
    brackets.length ? brackets.join(":") : "unbracketed";

  /** @type {Map<string, Record<string, import("@noflo/noflo").IP>>} */
  const stored = new Map();
  /** @type {Map<string, Record<string, boolean>>} */
  const released = new Map();
  /** @type {Map<string, Record<number, string[]>>} */
  const groupTrail = new Map();
  c.tearDown = async () => {
    stored.clear();
    released.clear();
    groupTrail.clear();
  };

  /**
   * Structural type for the output port collection — the full
   * ProcessOutput type isn't re-exported from the package root.
   * @typedef {{ send(map: Record<string, unknown>): void }} OutputLike
   */

  /**
   * @param {OutputLike} output
   * @param {string|null} scope
   * @param {unknown[]} brackets
   */
  const release = (output, scope, brackets) => {
    const identifier = getIdentifier(brackets);
    const scopeKey = scope ?? "null";
    let releasedScope = released.get(scopeKey);
    if (!releasedScope) {
      releasedScope = {};
      released.set(scopeKey, releasedScope);
    }
    releasedScope[identifier] = true;
    const storedScope = stored.get(scopeKey);
    if (!storedScope?.[identifier]) {
      return;
    }
    for (const bracket of brackets) {
      output.send({ out: new IP("openBracket", bracket) });
    }
    output.send({ out: storedScope[identifier] });
    for (const bracket of brackets.slice().reverse()) {
      output.send({ out: new IP("closeBracket", bracket) });
    }
    // Mark as non-released after sending
    releasedScope[identifier] = false;
  };

  c.process((input, output) => {
    if (input.hasStream("in")) {
      // Time to release some data
      const stream = /** @type {import("@noflo/noflo").IP[]} */ (
        input.getStream("in")
      );
      /** @type {unknown[]} */
      const brackets = [];
      for (const packet of stream) {
        if (packet.type === "openBracket") {
          brackets.push(packet.data);
          continue;
        }
        if (packet.type === "data") {
          release(output, input.scope, brackets);
          continue;
        }
        if (packet.type === "closeBracket") {
          brackets.pop();
        }
      }
      output.done();
      return;
    }

    // Store data to be released
    const indexesWithIps = /** @type {number[]} */ (
      input.attached("data")
    ).filter((idx) => input.has(["data", idx]));
    if (!indexesWithIps.length) {
      return;
    }
    for (const idx of indexesWithIps) {
      const scopeKey = input.scope ?? "null";
      let trailScope = groupTrail.get(scopeKey);
      if (!trailScope) {
        trailScope = {};
        groupTrail.set(scopeKey, trailScope);
      }
      if (!trailScope[idx]) {
        trailScope[idx] = [];
      }
      const packet = /** @type {import("@noflo/noflo").IP} */ (
        input.get(["data", idx])
      );
      if (packet.type === "openBracket") {
        trailScope[idx].push(packet.data);
        continue;
      }
      if (packet.type === "data") {
        const identifier = getIdentifier(trailScope[idx]);
        let storedScope = stored.get(scopeKey);
        if (!storedScope) {
          storedScope = {};
          stored.set(scopeKey, storedScope);
        }
        packet.index = null;
        storedScope[identifier] = packet;
        const releasedScope = released.get(scopeKey);
        if (releasedScope?.[identifier]) {
          // This identifier was already released. Send right away
          release(output, input.scope, trailScope[idx]);
        }
        continue;
      }
      if (packet.type === "closeBracket") {
        trailScope[idx].pop();
      }
    }
    output.done();
  });

  return c;
}
