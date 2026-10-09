import { Component } from "@noflo/noflo";

/**
 * Collects a stream of packets into an object keyed by its groups. Data
 * IPs are stored under a `$data` property on each level; a group named
 * `$data` is an error.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Collect a stream of packets into object keyed by its groups",
    forwardBrackets: {},
    inPorts: {
      in: {
        datatype: "all",
        description: "IPs to collect",
        required: true,
      },
    },
    outPorts: {
      out: {
        datatype: "object",
        description:
          "An object containing input IPs sorted by their group names",
      },
      error: { datatype: "object" },
    },
  });

  c.process((input, output) => {
    if (!input.hasStream("in")) {
      return;
    }
    const stream = /** @type {import("@noflo/noflo").IP[]} */ (
      input.getStream("in")
    );
    if (stream[0].type === "openBracket" && stream[0].data == null) {
      // Remove the surrounding brackets if they're unnamed
      stream.shift();
      stream.pop();
    }

    // Working variable for incoming IPs
    /** @type {Record<string, unknown>} */
    let data = {};
    // Breadcrumb of incoming groups
    /** @type {unknown[]} */
    const groupTrail = [];
    // Breadcrumb of each level of IPs as partitioned by groups
    /** @type {Record<string, unknown>[]} */
    const parents = [];

    for (const packet of stream) {
      if (packet.type === "openBracket") {
        // The attribute name `$data` indicates data IPs in the outgoing
        // structure, so no group may be named `$data`
        if (packet.data === "$data") {
          output.done(new Error("groups cannot be named '$data'"));
          return;
        }
        // Save whatever is in the working memory right now into its own level
        parents.push(data);
        // Save the current group
        groupTrail.push(packet.data);
        // Clear working memory for the new level
        data = {};
        continue;
      }
      if (packet.type === "data") {
        const level = data;
        if (!level.$data) {
          level.$data = [];
        }
        /** @type {unknown[]} */ (level.$data).push(packet.data);
        continue;
      }
      if (packet.type === "closeBracket") {
        // Temporarily save working memory
        const oldData = data;
        // Take out the previous level
        data = /** @type {Record<string, unknown>} */ (parents.pop());
        // Put the working memory into the previous level under the group
        // name being closed
        const child = /** @type {string} */ (groupTrail.pop());
        if (!(child in data)) {
          data[child] = oldData;
          continue;
        }
        // If it's already an array, append to it
        if (Array.isArray(data[child])) {
          /** @type {unknown[]} */ (data[child]).push(oldData);
          continue;
        }
        // If something already exists in place but isn't appendable, make
        // it so by having whatever is in it as the first array element
        data[child] = [data[child], oldData];
      }
    }

    output.sendDone({ out: data });
  });

  return c;
}
