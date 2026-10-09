import { Component, IP } from "@noflo/noflo";

/**
 * Replaces group names based on a static `map` (either an object or a
 * `from=to` string) or a `regexp` map (`pattern=replacement`), applied
 * in object order. Data IPs and non-string bracket names pass through.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Replace groups based on static or regexp map",
    forwardBrackets: {},
    inPorts: {
      map: { datatype: "all", control: true },
      regexp: { datatype: "all", control: true },
      in: { datatype: "all", required: true },
    },
    outPorts: {
      out: { datatype: "all" },
    },
  });

  c.process((input, output) => {
    if (!input.has("in")) {
      return;
    }
    if (input.attached("map").length && !input.hasData("map")) {
      return;
    }
    if (input.attached("regexp").length && !input.hasData("regexp")) {
      return;
    }
    /** @type {Record<string, string>} */
    let map = {};
    /** @type {Record<string, string>} */
    let regexp = {};
    if (input.hasData("map")) {
      const mapData = input.getData("map");
      if (typeof mapData === "object") {
        map = mapData;
      } else {
        const mapParts = mapData.split("=");
        map[mapParts[0]] = mapParts[1];
      }
    }
    if (input.hasData("regexp")) {
      const regexpData = input.getData("regexp");
      if (typeof regexpData === "object") {
        regexp = regexpData;
      } else {
        const regexpParts = regexpData.split("=");
        regexp[regexpParts[0]] = regexpParts[1];
      }
    }
    const packet = /** @type {import("@noflo/noflo").IP} */ (input.get("in"));
    if (packet.type === "data") {
      output.sendDone({ out: packet });
      return;
    }
    if (packet.type === "openBracket" || packet.type === "closeBracket") {
      if (typeof packet.data !== "string") {
        output.sendDone({ out: packet });
        return;
      }

      if (map[packet.data]) {
        // Direct mapping
        output.sendDone({ out: new IP(packet.type, map[packet.data]) });
        return;
      }

      let group = packet.data;
      for (const [expression, replacement] of Object.entries(regexp)) {
        const exp = new RegExp(expression);
        const matched = exp.exec(group);
        if (!matched) {
          continue;
        }
        group = group.replace(exp, replacement);
      }
      output.sendDone({ out: new IP(packet.type, group) });
      return;
    }
    output.done();
  });

  return c;
}
