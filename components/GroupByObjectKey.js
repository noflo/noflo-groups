import { Component, IP } from "@noflo/noflo";

/**
 * Groups IPs by a key in their payload. Boolean `true` values group by
 * the property name itself; non-string values group as `undefined`.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Group IPs by a key in their payload",
    forwardBrackets: {},
    inPorts: {
      in: { datatype: "object", required: true },
      key: { datatype: "string", control: true, required: true },
    },
    outPorts: {
      out: { datatype: "object" },
      error: { datatype: "object" },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("in", "key")) {
      return;
    }
    const [data, key] = input.getData("in", "key");
    if (typeof data !== "object") {
      output.done(new Error("Data is not an object"));
      return;
    }
    const payload = /** @type {Record<string, unknown>} */ (data);
    let group = payload[key];
    if (typeof payload[key] !== "string") {
      group = "undefined";
    }
    if (typeof payload[key] === "boolean" && payload[key]) {
      group = key;
    }
    output.send({ out: new IP("openBracket", group) });
    output.send({ out: data });
    output.send({ out: new IP("closeBracket", group) });
    output.done();
  });

  return c;
}
