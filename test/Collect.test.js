import assert from "node:assert/strict";
import { describe, it } from "node:test";
import * as noflo from "@noflo/noflo";

import { getComponent as getCollectGroups } from "../components/CollectGroups.js";
import { getComponent as getCollectObject } from "../components/CollectObject.js";
import { getComponent as getCollectTree } from "../components/CollectTree.js";
import { getComponent as getSendByGroup } from "../components/SendByGroup.js";
import { collect, sendGrouped } from "./helpers.js";

describe("CollectGroups component", () => {
  /** @returns {{ c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, outIps: import("@noflo/noflo").IP[], errorIps: import("@noflo/noflo").IP[] }} */
  const build = () => {
    const c = getCollectGroups();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    const errorSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    c.outPorts.error.attach(errorSocket);
    return {
      c,
      inSocket,
      outIps: collect(outSocket),
      errorIps: collect(errorSocket),
    };
  };

  it("collects data IPs under $data with no groups inside the stream", () => {
    const { c, inSocket, outIps } = build();
    sendGrouped(inSocket, [null], ["a", "b", "c"]);
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ $data: ["a", "b", "c"] }],
    );
    c.tearDown?.();
  });

  it("collects one group", () => {
    const { c, inSocket, outIps } = build();
    inSocket.post(new noflo.IP("openBracket", null));
    inSocket.post(new noflo.IP("openBracket", "g1"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("data", "b"));
    inSocket.post(new noflo.IP("closeBracket", "g1"));
    inSocket.post(new noflo.IP("data", "c"));
    inSocket.post(new noflo.IP("closeBracket", null));
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ g1: { $data: ["a", "b"] }, $data: ["c"] }],
    );
    c.tearDown?.();
  });

  it("rejects a group named $data", () => {
    const { c, inSocket, errorIps } = build();
    inSocket.post(new noflo.IP("openBracket", "$data"));
    inSocket.post(new noflo.IP("data", 1));
    inSocket.post(new noflo.IP("closeBracket", "$data"));
    assert.equal(errorIps.length, 1);
    assert.equal(
      /** @type {Error} */ (errorIps[0].data).message,
      "groups cannot be named '$data'",
    );
    c.tearDown?.();
  });

  it("collects two groups", () => {
    const { c, inSocket, outIps } = build();
    inSocket.post(new noflo.IP("openBracket", null));
    inSocket.post(new noflo.IP("openBracket", "g1"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("data", "b"));
    inSocket.post(new noflo.IP("closeBracket", "g1"));
    inSocket.post(new noflo.IP("openBracket", "g2"));
    inSocket.post(new noflo.IP("data", "c"));
    inSocket.post(new noflo.IP("data", "d"));
    inSocket.post(new noflo.IP("closeBracket", "g2"));
    inSocket.post(new noflo.IP("closeBracket", null));
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ g1: { $data: ["a", "b"] }, g2: { $data: ["c", "d"] } }],
    );
    c.tearDown?.();
  });

  it("collates two same-named groups into an array", () => {
    const { c, inSocket, outIps } = build();
    inSocket.post(new noflo.IP("openBracket", null));
    inSocket.post(new noflo.IP("openBracket", "g1"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("data", "b"));
    inSocket.post(new noflo.IP("closeBracket", "g1"));
    inSocket.post(new noflo.IP("openBracket", "g1"));
    inSocket.post(new noflo.IP("data", "c"));
    inSocket.post(new noflo.IP("data", "d"));
    inSocket.post(new noflo.IP("closeBracket", "g1"));
    inSocket.post(new noflo.IP("closeBracket", null));
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ g1: [{ $data: ["a", "b"] }, { $data: ["c", "d"] }] }],
    );
    c.tearDown?.();
  });

  it("collects nested groups", () => {
    const { c, inSocket, outIps } = build();
    inSocket.post(new noflo.IP("openBracket", "g1"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("openBracket", "g2"));
    inSocket.post(new noflo.IP("data", "c"));
    inSocket.post(new noflo.IP("data", "d"));
    inSocket.post(new noflo.IP("closeBracket", "g2"));
    inSocket.post(new noflo.IP("data", "b"));
    inSocket.post(new noflo.IP("closeBracket", "g1"));
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ g1: { $data: ["a", "b"], g2: { $data: ["c", "d"] } } }],
    );
    c.tearDown?.();
  });

  it("collects object data", () => {
    const { c, inSocket, outIps } = build();
    sendGrouped(
      inSocket,
      ["g1"],
      [
        { a: 1, b: 2 },
        { b: 3, c: 4 },
      ],
    );
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [
        {
          g1: {
            $data: [
              { a: 1, b: 2 },
              { b: 3, c: 4 },
            ],
          },
        },
      ],
    );
    c.tearDown?.();
  });

  it("collects array data", () => {
    const { c, inSocket, outIps } = build();
    sendGrouped(
      inSocket,
      ["g1"],
      [
        ["a", "b"],
        ["c", "d"],
      ],
    );
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [
        {
          g1: {
            $data: [
              ["a", "b"],
              ["c", "d"],
            ],
          },
        },
      ],
    );
    c.tearDown?.();
  });
});

describe("CollectTree component", () => {
  /** @returns {{ c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, levelSocket: import("@noflo/noflo").internalSocket.InternalSocket | null, outIps: import("@noflo/noflo").IP[], errorIps: import("@noflo/noflo").IP[] }} */
  const build = (attachLevel = false) => {
    const c = getCollectTree();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    const errorSocket = noflo.internalSocket.createSocket();
    /** @type {import("@noflo/noflo").internalSocket.InternalSocket|null} */
    let levelSocket = null;
    c.inPorts.in.attach(inSocket);
    if (attachLevel) {
      levelSocket = noflo.internalSocket.createSocket();
      c.inPorts.level.attach(levelSocket);
    }
    c.outPorts.out.attach(outSocket);
    c.outPorts.error.attach(errorSocket);
    return {
      c,
      inSocket,
      levelSocket,
      outIps: collect(outSocket),
      errorIps: collect(errorSocket),
    };
  };

  it("sends an error when no group information was collected", () => {
    const { c, inSocket, errorIps } = build();
    inSocket.post(new noflo.IP("data", "foo"));
    assert.equal(errorIps.length, 1);
    assert.equal(
      /** @type {Error} */ (errorIps[0].data).message,
      "No tree information was collected",
    );
    c.tearDown?.();
  });

  it("collects a single-level group", () => {
    const { c, inSocket, outIps } = build();
    sendGrouped(inSocket, ["foo"], ["bar"]);
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ foo: "bar" }],
    );
    c.tearDown?.();
  });

  it("collects two packets under one group into an array", () => {
    const { c, inSocket, outIps } = build();
    sendGrouped(inSocket, ["foo"], ["bar", "baz"]);
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ foo: ["bar", "baz"] }],
    );
    c.tearDown?.();
  });

  it("collects two same-named groups despite a surrounding unnamed group", () => {
    const { c, inSocket, outIps } = build();
    inSocket.post(new noflo.IP("openBracket", null));
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "bar"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "baz"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    inSocket.post(new noflo.IP("closeBracket", null));
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ foo: ["bar", "baz"] }],
    );
    c.tearDown?.();
  });

  it("collects multi-level groups", () => {
    const { c, inSocket, outIps } = build();
    sendGrouped(inSocket, ["baz", "foo"], ["bar"]);
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ baz: { foo: "bar" } }],
    );
    c.tearDown?.();
  });

  it("forwards outer groups above the level control", () => {
    const { c, inSocket, levelSocket, outIps } = build(true);
    levelSocket?.post(new noflo.IP("data", 1));
    sendGrouped(inSocket, ["outer", "inner"], ["a"]);
    // level=1: 'outer' forwarded, 'inner' collected
    assert.deepEqual(rendered(outIps), ["< outer", 'DATA {"inner":"a"}', ">"]);
    c.tearDown?.();
  });
});

/**
 * @param {import("@noflo/noflo").IP[]} ips
 * @returns {string[]}
 */
const rendered = (ips) =>
  ips.map((ip) => {
    if (ip.type === "openBracket") {
      return `< ${String(ip.data)}`;
    }
    if (ip.type === "closeBracket") {
      return ">";
    }
    return `DATA ${JSON.stringify(ip.data)}`;
  });

describe("CollectObject component", () => {
  /**
   * @param {boolean} [attachAllpackets]
   * @param {boolean} [attachClear]
   * @returns {{ c: import("@noflo/noflo").Component, keysSocket: import("@noflo/noflo").internalSocket.InternalSocket, allpacketsSocket: import("@noflo/noflo").internalSocket.InternalSocket, releaseSocket: import("@noflo/noflo").internalSocket.InternalSocket, clearSocket: import("@noflo/noflo").internalSocket.InternalSocket, outIps: import("@noflo/noflo").IP[] }}
   */
  const build = (attachAllpackets = false, attachClear = false) => {
    const c = getCollectObject();
    const keysSocket = noflo.internalSocket.createSocket();
    const allpacketsSocket = noflo.internalSocket.createSocket();
    const releaseSocket = noflo.internalSocket.createSocket();
    const clearSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.keys.attach(keysSocket);
    if (attachAllpackets) {
      c.inPorts.allpackets.attach(allpacketsSocket);
    }
    c.inPorts.release.attach(releaseSocket);
    if (attachClear) {
      c.inPorts.clear.attach(clearSocket);
    }
    c.outPorts.out.attach(outSocket);
    return {
      c,
      keysSocket,
      allpacketsSocket,
      releaseSocket,
      clearSocket,
      outIps: collect(outSocket),
    };
  };

  it("collects packets keyed by connection index", () => {
    const { c, keysSocket, releaseSocket, outIps } = build();
    const c0 = noflo.internalSocket.createSocket();
    const c1 = noflo.internalSocket.createSocket();
    c.inPorts.collect.attach(c0, 0);
    c.inPorts.collect.attach(c1, 1);
    keysSocket.post(new noflo.IP("data", "name,value"));
    c0.post(new noflo.IP("data", "foo"));
    c1.post(new noflo.IP("data", 42));
    releaseSocket.post(new noflo.IP("data", null));
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ name: "foo", value: 42 }],
    );
    c.tearDown?.();
  });

  it("collects arrays for allpackets connections", () => {
    // allpackets entries mark which connections collect all packets;
    // the key still comes from the keys port
    const { c, keysSocket, allpacketsSocket, releaseSocket, outIps } =
      build(true);
    const c0 = noflo.internalSocket.createSocket();
    const c1 = noflo.internalSocket.createSocket();
    c.inPorts.collect.attach(c0, 0);
    c.inPorts.collect.attach(c1, 1);
    keysSocket.post(new noflo.IP("data", "name"));
    keysSocket.post(new noflo.IP("data", "value"));
    allpacketsSocket.post(new noflo.IP("data", "name"));
    c0.post(new noflo.IP("data", "foo"));
    c1.post(new noflo.IP("data", "one"));
    c1.post(new noflo.IP("data", "two"));
    releaseSocket.post(new noflo.IP("data", null));
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ name: ["foo"], value: "two" }],
    );
    c.tearDown?.();
  });

  it("uses the first-level group as key", () => {
    const { c, keysSocket, releaseSocket, outIps } = build();
    const c0 = noflo.internalSocket.createSocket();
    c.inPorts.collect.attach(c0, 0);
    keysSocket.post(new noflo.IP("data", "name"));
    c0.post(new noflo.IP("openBracket", "g1"));
    c0.post(new noflo.IP("data", "foo"));
    c0.post(new noflo.IP("closeBracket", "g1"));
    releaseSocket.post(new noflo.IP("data", null));
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{ g1: { name: "foo" } }],
    );
    c.tearDown?.();
  });

  it("clears collected data", () => {
    const { c, keysSocket, releaseSocket, clearSocket, outIps } = build(
      false,
      true,
    );
    const c0 = noflo.internalSocket.createSocket();
    c.inPorts.collect.attach(c0, 0);
    keysSocket.post(new noflo.IP("data", "name"));
    c0.post(new noflo.IP("data", "foo"));
    clearSocket.post(new noflo.IP("data", null));
    releaseSocket.post(new noflo.IP("data", null));
    assert.deepEqual(
      outIps.filter((ip) => ip.type === "data").map((ip) => ip.data),
      [{}],
    );
    c.tearDown?.();
  });
});

describe("SendByGroup component", () => {
  /** @returns {{ c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, dataSocket: import("@noflo/noflo").internalSocket.InternalSocket, outIps: import("@noflo/noflo").IP[] }} */
  const build = () => {
    const c = getSendByGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const dataSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.inPorts.data.attach(dataSocket);
    c.outPorts.out.attach(outSocket);
    return {
      c,
      inSocket,
      dataSocket,
      outIps: collect(outSocket),
    };
  };

  /**
   * @param {import("@noflo/noflo").IP[]} ips
   * @returns {string[]}
   */
  const rendered = (ips) =>
    ips.map((ip) => {
      if (ip.type === "openBracket") {
        return `< ${String(ip.data)}`;
      }
      if (ip.type === "closeBracket") {
        return ">";
      }
      return `DATA ${JSON.stringify(ip.data)}`;
    });

  it("releases the stored packet when receiving a matching bang", () => {
    const { c, inSocket, dataSocket, outIps } = build();
    dataSocket.post(new noflo.IP("data", "payload"));
    inSocket.post(new noflo.IP("data", null));
    assert.deepEqual(rendered(outIps), ['DATA "payload"']);
    c.tearDown?.();
  });

  it("does not release on an unrelated group bang", () => {
    const { c, inSocket, dataSocket, outIps } = build();
    sendGrouped(dataSocket, ["g1"], ["payload"]);
    inSocket.post(new noflo.IP("data", null));
    assert.deepEqual(rendered(outIps), []);
    c.tearDown?.();
  });

  it("releases the packet grouped by its storage groups", () => {
    const { c, inSocket, dataSocket, outIps } = build();
    sendGrouped(dataSocket, ["g1"], ["payload"]);
    inSocket.post(new noflo.IP("openBracket", "g1"));
    inSocket.post(new noflo.IP("data", null));
    inSocket.post(new noflo.IP("closeBracket", "g1"));
    assert.deepEqual(rendered(outIps), ["< g1", 'DATA "payload"', ">"]);
    c.tearDown?.();
  });

  it("releases immediately when the bang was already received", () => {
    const { c, inSocket, dataSocket, outIps } = build();
    inSocket.post(new noflo.IP("openBracket", "g1"));
    inSocket.post(new noflo.IP("data", null));
    inSocket.post(new noflo.IP("closeBracket", "g1"));
    sendGrouped(dataSocket, ["g1"], ["payload"]);
    assert.deepEqual(rendered(outIps), ["< g1", 'DATA "payload"', ">"]);
    c.tearDown?.();
  });

  it("releases the ungrouped packet on an ungrouped bang", () => {
    const { c, inSocket, dataSocket, outIps } = build();
    dataSocket.post(new noflo.IP("data", "first"));
    sendGrouped(dataSocket, ["g1"], ["second"]);
    inSocket.post(new noflo.IP("data", null));
    // 'ungrouped' identifier matches the plain data; the grouped one
    // stays stored
    assert.deepEqual(rendered(outIps), ['DATA "first"']);
    c.tearDown?.();
  });
});
