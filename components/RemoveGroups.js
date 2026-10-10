import { Component } from "@noflo/noflo";

/**
 * Removes brackets matching a string or a regex, or all brackets when no
 * `regexp` is given. Data IPs always pass through.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "Remove brackets matching a string or a regex string, or all if no regexp given",
    forwardBrackets: {},
    inPorts: {
      in: {
        datatype: "all",
        description: "IPs to forward",
        required: true,
      },
      regexp: {
        datatype: "string",
        description: "Regexp used to remove brackets",
        control: true,
      },
    },
    outPorts: {
      out: { datatype: "all" },
    },
  });

  c.process((input, output) => {
    if (!input.has("in")) {
      return;
    }
    if (input.attached("regexp").length && !input.hasData("regexp")) {
      return;
    }
    let regexp = null;
    if (input.hasData("regexp")) {
      regexp = new RegExp(input.getData("regexp"));
    }
    const packet = /** @type {import("@noflo/noflo").IP} */ (input.get("in"));
    if (packet.type === "openBracket" || packet.type === "closeBracket") {
      if (!regexp) {
        // No regexp given, remove all brackets
        output.done();
        return;
      }
      if (typeof packet.data === "string" && packet.data.match(regexp)) {
        // Matches regexp, remove
        output.done();
        return;
      }
      // Doesn't match regexp, send
      output.sendDone({ out: packet });
      return;
    }
    if (packet.type === "data") {
      output.sendDone({ out: packet });
    }
  });

  return c;
}
