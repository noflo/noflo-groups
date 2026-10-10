import { randomUUID } from "node:crypto";

import { Component, IP } from "@noflo/noflo";

/**
 * Wraps each incoming data IP into a bracket named by a generated random
 * UUID. Incoming brackets are forwarded by the default bracket-forwarding
 * behavior, as in 1.x.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Wrap IPs into a random UUID generated bracket",
    inPorts: {
      in: {
        datatype: "all",
        description: "IPs to forward",
        required: true,
      },
    },
    outPorts: {
      out: { datatype: "all" },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("in")) {
      return;
    }
    const data = input.getData("in");
    const identifier = randomUUID();
    output.send({ out: new IP("openBracket", identifier) });
    output.send({ out: data });
    output.send({ out: new IP("closeBracket", identifier) });
    output.done();
  });

  return c;
}
