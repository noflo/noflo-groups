import { Component, IP } from "@noflo/noflo";

/**
 * Groups IPs by a key in their payload. Boolean `true` values bracket by
 * the property name itself; non-string values bracket as `undefined`.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Bracket IPs by a key in their payload",
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
    let bracket = payload[key];
    if (typeof payload[key] !== "string") {
      bracket = "undefined";
    }
    if (typeof payload[key] === "boolean" && payload[key]) {
      bracket = key;
    }
    output.send({ out: new IP("openBracket", bracket) });
    output.send({ out: data });
    output.send({ out: new IP("closeBracket", bracket) });
    output.done();
  });

  return c;
}
