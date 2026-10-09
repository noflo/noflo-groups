import assert from "node:assert/strict";
import { describe, it } from "node:test";
import * as noflo from "@noflo/noflo";

import { getComponent as getReadGroup } from "../components/ReadGroup.js";
import { getComponent as getReadGroups } from "../components/ReadGroups.js";
import { collect, render } from "./helpers.js";

describe("ReadGroup component", () => {
  /** @returns {{ c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, outSocket: import("@noflo/noflo").internalSocket.InternalSocket, groupSocket: import("@noflo/noflo").internalSocket.InternalSocket, outIps: import("@noflo/noflo").IP[], groupIps: import("@noflo/noflo").IP[] }} */
  const build = () => {
    const c = getReadGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    const groupSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    c.outPorts.group.attach(groupSocket);
    return {
      c,
      inSocket,
      outSocket,
      groupSocket,
      outIps: collect(outSocket),
      groupIps: collect(groupSocket),
    };
  };

  it("reads a group", async () => {
    const { c, inSocket, groupIps } = build();
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "hello"));
    assert.equal(groupIps[0].data, "foo");
    c.tearDown?.(() => {});
  });

  it("reads nested groups as a colon trail", async () => {
    const { c, inSocket, groupIps } = build();
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "bar"));
    inSocket.post(new noflo.IP("data", "hello"));
    // Intermediate opens report their own names; the data IP reports
    // the full trail
    assert.deepEqual(
      groupIps.map((ip) => ip.data),
      ["foo", "bar", "foo:bar"],
    );
    c.tearDown?.(() => {});
  });

  it("forwards brackets on out with the trail closing", () => {
    const { c, inSocket, outIps, groupIps } = build();
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "hello"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(outIps), ["< foo", 'DATA "hello"', ">"]);
    // The group port receives clones of the bracket packets
    assert.equal(groupIps[0].type, "openBracket");
    assert.equal(groupIps[groupIps.length - 1].type, "closeBracket");
    c.tearDown?.(() => {});
  });
});

describe("ReadGroups component", () => {
  /** @returns {{ c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, stripSocket: import("@noflo/noflo").internalSocket.InternalSocket|null, thresholdSocket: import("@noflo/noflo").internalSocket.InternalSocket|null, outIps: import("@noflo/noflo").IP[], groupIps: import("@noflo/noflo").IP[] }} */
  const build = (attachStrip = false, attachThreshold = false) => {
    const c = getReadGroups();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    const groupSocket = noflo.internalSocket.createSocket();
    /** @type {import("@noflo/noflo").internalSocket.InternalSocket|null} */
    let stripSocket = null;
    /** @type {import("@noflo/noflo").internalSocket.InternalSocket|null} */
    let thresholdSocket = null;
    c.inPorts.in.attach(inSocket);
    if (attachStrip) {
      stripSocket = noflo.internalSocket.createSocket();
      c.inPorts.strip.attach(stripSocket);
    }
    if (attachThreshold) {
      thresholdSocket = noflo.internalSocket.createSocket();
      c.inPorts.threshold.attach(thresholdSocket);
    }
    c.outPorts.out.attach(outSocket);
    c.outPorts.group.attach(groupSocket);
    return {
      c,
      inSocket,
      stripSocket,
      thresholdSocket,
      outIps: collect(outSocket),
      groupIps: collect(groupSocket),
    };
  };

  it("forwards all brackets and reports each group name", () => {
    const { c, inSocket, outIps, groupIps } = build();
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "bar"));
    inSocket.post(new noflo.IP("data", "hello"));
    inSocket.post(new noflo.IP("closeBracket", "bar"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(outIps), [
      "< foo",
      "< bar",
      'DATA "hello"',
      ">",
      ">",
    ]);
    assert.deepEqual(
      groupIps.map((ip) => ip.data),
      ["foo", "bar"],
    );
    c.tearDown?.(() => {});
  });

  it("strips brackets when strip is true", () => {
    const { c, inSocket, stripSocket, outIps, groupIps } = build(true);
    stripSocket?.post(new noflo.IP("data", true));
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "hello"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(outIps), ['DATA "hello"']);
    assert.deepEqual(
      groupIps.map((ip) => ip.data),
      ["foo"],
    );
    c.tearDown?.(() => {});
  });

  it("forwards bracket levels above the threshold unreported", () => {
    const { c, inSocket, thresholdSocket, outIps, groupIps } = build(
      false,
      true,
    );
    thresholdSocket?.post(new noflo.IP("data", 1));
    inSocket.post(new noflo.IP("openBracket", "outer"));
    inSocket.post(new noflo.IP("openBracket", "inner"));
    inSocket.post(new noflo.IP("data", "hello"));
    inSocket.post(new noflo.IP("closeBracket", "inner"));
    inSocket.post(new noflo.IP("closeBracket", "outer"));
    // 'outer' is level 1, within threshold 1 → forwarded and reported;
    // 'inner' is level 2 > 1 → forwarded but not reported
    assert.deepEqual(render(outIps), [
      "< outer",
      "< inner",
      'DATA "hello"',
      ">",
      ">",
    ]);
    assert.deepEqual(
      groupIps.map((ip) => ip.data),
      ["outer"],
    );
    c.tearDown?.(() => {});
  });

  it("reports levels within the threshold", () => {
    const { c, inSocket, thresholdSocket, groupIps } = build(false, true);
    thresholdSocket?.post(new noflo.IP("data", 3));
    inSocket.post(new noflo.IP("openBracket", "outer"));
    inSocket.post(new noflo.IP("openBracket", "inner"));
    inSocket.post(new noflo.IP("data", "hello"));
    assert.deepEqual(
      groupIps.map((ip) => ip.data),
      ["outer", "inner"],
    );
    c.tearDown?.(() => {});
  });
});
