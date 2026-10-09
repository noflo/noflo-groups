import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import { describe, it } from "node:test";
import { fileURLToPath } from "node:url";
import { parse } from "@noflo/fbp";
import { createNodeModulesRegistry } from "@noflo/loader-node";
import * as noflo from "@noflo/noflo";
import { Component, IP } from "@noflo/noflo";

const testDir = path.dirname(fileURLToPath(import.meta.url));
// The package root: the loader discovers this package own components
// and node_modules from there
const baseDir = path.join(testDir, "..");

/**
 * A minimal stand-in for `core/Split`, used because `@noflo/core` is a
 * separate package the host graph consumer is expected to have installed.
 * The loader here only sees this package, so the graph's `core/Split` node
 * is registered with this double.
 */
const getSplit = () => {
  const c = new Component({
    description: "Split a single packet to all attached out connections",
    inPorts: { in: { datatype: "all" } },
    outPorts: { out: { datatype: "all" } },
  });
  c.process((input, output) => {
    if (!input.hasData("in")) {
      return;
    }
    const packet = input.getData("in");
    output.sendDone({ out: packet });
  });
  return c;
};

/** Loads the ObjectifyByGroup graph as a subgraph component. */
const loadGraph = async () => {
  const source = readFileSync(
    path.join(baseDir, "graphs", "ObjectifyByGroup.fbp"),
    "utf8",
  );
  const graphJson = parse(source);
  const graph = noflo.importFbpJson(graphJson);
  const registry = await createNodeModulesRegistry(baseDir);
  const loader = new noflo.ComponentLoader({ registry });
  loader.registerComponent("core", "Split", getSplit);
  loader.registerGraph("groups", "ObjectifyByGroup", graph);
  const component = await loader.load("groups/ObjectifyByGroup");
  return component;
};

/**
 * @param {import("@noflo/noflo").Component} component
 */
const wire = (component) => {
  const inSocket = noflo.internalSocket.createSocket();
  const regexpSocket = noflo.internalSocket.createSocket();
  const outSocket = noflo.internalSocket.createSocket();
  component.inPorts.in.attach(inSocket);
  component.inPorts.regexp.attach(regexpSocket);
  component.outPorts.out.attach(outSocket);
  return { inSocket, regexpSocket, outSocket };
};

/**
 * @param {import("@noflo/noflo").IP[]} socketIps
 * @returns {string[]}
 */
const render = (socketIps) =>
  socketIps.map((ip) => {
    if (ip.type === "openBracket") {
      return `< ${String(ip.data)}`;
    }
    if (ip.type === "closeBracket") {
      return ">";
    }
    return `DATA ${JSON.stringify(ip.data)}`;
  });

describe("ObjectifyByGroup graph", () => {
  it("makes an object and removes groups matching the regexp", async () => {
    const component = await loadGraph();
    const { inSocket, regexpSocket, outSocket } = wire(component);
    /** @type {import("@noflo/noflo").IP[]} */
    const ips = [];
    outSocket.addEventListener(
      "ip",
      /** @param {CustomEvent} event */ (event) => {
        ips.push(event.detail);
      },
    );
    regexpSocket.post(new noflo.IP("data", "^(a)"));
    inSocket.post(new noflo.IP("openBracket", "abc"));
    inSocket.post(new noflo.IP("data", "whatever"));
    inSocket.post(new noflo.IP("closeBracket", "abc"));
    await new Promise((resolve) => setTimeout(resolve, 100));
    assert.deepEqual(render(ips), ['DATA {"a":"whatever"}']);
  });

  it("passes packets through as-is when groups do not match", async () => {
    const component = await loadGraph();
    const { inSocket, regexpSocket, outSocket } = wire(component);
    /** @type {import("@noflo/noflo").IP[]} */
    const ips = [];
    outSocket.addEventListener(
      "ip",
      /** @param {CustomEvent} event */ (event) => {
        ips.push(event.detail);
      },
    );
    regexpSocket.post(new noflo.IP("data", "^(a)"));
    inSocket.post(new noflo.IP("openBracket", "xyz"));
    inSocket.post(new noflo.IP("data", "whatever"));
    inSocket.post(new noflo.IP("closeBracket", "xyz"));
    await new Promise((resolve) => setTimeout(resolve, 100));
    assert.deepEqual(render(ips), ["< xyz", 'DATA "whatever"', ">"]);
  });
});
