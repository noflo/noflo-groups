import assert from "node:assert/strict";
import { describe, it } from "node:test";
import * as noflo from "@noflo/noflo";

import { getComponent as getFilterByGroup } from "../components/FilterByGroup.js";
import { getComponent as getFirstGroup } from "../components/FirstGroup.js";
import { getComponent as getLastGroup } from "../components/LastGroup.js";
import { getComponent as getMergeGroups } from "../components/MergeGroups.js";
import { getComponent as getObjectify } from "../components/Objectify.js";
import { getComponent as getRegroup } from "../components/Regroup.js";
import { getComponent as getRemoveGroups } from "../components/RemoveGroups.js";
import { collect, render } from "./helpers.js";

describe("FirstGroup component", () => {
  it("sends unbracketed packets as-is", () => {
    const c = getFirstGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("data", "a"));
    assert.deepEqual(render(ips), ['DATA "a"']);
    c.tearDown?.();
  });

  it("keeps only the first (outermost) group level", () => {
    const c = getFirstGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "bar"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "bar"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(ips), ["< foo", 'DATA "a"', ">"]);
    c.tearDown?.();
  });

  it("keeps the first group across sibling substreams", () => {
    const c = getFirstGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "bar"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "bar"));
    inSocket.post(new noflo.IP("openBracket", "baz"));
    inSocket.post(new noflo.IP("data", "b"));
    inSocket.post(new noflo.IP("closeBracket", "baz"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(ips), ["< foo", 'DATA "a"', 'DATA "b"', ">"]);
    c.tearDown?.();
  });
});

describe("LastGroup component", () => {
  it("sends unbracketed packets as-is", () => {
    const c = getLastGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("data", "a"));
    assert.deepEqual(render(ips), ['DATA "a"']);
    c.tearDown?.();
  });

  it("keeps a single group", () => {
    const c = getLastGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(ips), ["< foo", 'DATA "a"', ">"]);
    c.tearDown?.();
  });

  it("keeps only the last (innermost) group with data", () => {
    const c = getLastGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "bar"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "bar"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(ips), ["< bar", 'DATA "a"', ">"]);
    c.tearDown?.();
  });

  it("keeps one group around two IPs", () => {
    const c = getLastGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("data", "b"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(ips), ["< foo", 'DATA "a"', 'DATA "b"', ">"]);
    c.tearDown?.();
  });
});

describe("MergeGroups component", () => {
  it("sends unbracketed packets as-is", () => {
    const c = getMergeGroups();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("data", "a"));
    assert.deepEqual(render(ips), ['DATA "a"']);
    c.tearDown?.();
  });

  it("keeps a single-level stream as-is", () => {
    const c = getMergeGroups();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("data", "b"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(ips), ["< foo", 'DATA "a"', 'DATA "b"', ">"]);
    c.tearDown?.();
  });

  it("flattens a stream with substreams to one level", () => {
    const c = getMergeGroups();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "bar"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("openBracket", "baz"));
    inSocket.post(new noflo.IP("data", "b"));
    inSocket.post(new noflo.IP("closeBracket", "baz"));
    inSocket.post(new noflo.IP("closeBracket", "bar"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(ips), ["< foo:bar", 'DATA "a"', 'DATA "b"', ">"]);
    c.tearDown?.();
  });
});

describe("FilterByGroup component", () => {
  /** @returns {{ c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, regexpSocket: import("@noflo/noflo").internalSocket.InternalSocket, outIps: import("@noflo/noflo").IP[], groupIps: import("@noflo/noflo").IP[], emptyIps: import("@noflo/noflo").IP[] }} */
  const build = () => {
    const c = getFilterByGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const regexpSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    const groupSocket = noflo.internalSocket.createSocket();
    const emptySocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.inPorts.regexp.attach(regexpSocket);
    c.outPorts.out.attach(outSocket);
    c.outPorts.group.attach(groupSocket);
    c.outPorts.empty.attach(emptySocket);
    return {
      c,
      inSocket,
      regexpSocket,
      outIps: collect(outSocket),
      groupIps: collect(groupSocket),
      emptyIps: collect(emptySocket),
    };
  };

  it("sends only content with matching top-level group", () => {
    const { c, inSocket, regexpSocket, outIps, groupIps } = build();
    regexpSocket.post(new noflo.IP("data", "^foo"));
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "bar"));
    inSocket.post(new noflo.IP("data", "b"));
    inSocket.post(new noflo.IP("closeBracket", "bar"));
    assert.deepEqual(render(outIps), ['DATA "a"']);
    assert.deepEqual(
      groupIps.map((ip) => ip.data),
      ["foo"],
    );
    c.tearDown?.();
  });

  it("sends sub-groups of the matching group", () => {
    const { c, inSocket, regexpSocket, outIps } = build();
    regexpSocket.post(new noflo.IP("data", "^foo"));
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "sub"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "sub"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(outIps), ["< sub", 'DATA "a"', ">"]);
    c.tearDown?.();
  });

  it("sends an empty bang when nothing matched", () => {
    const { c, inSocket, regexpSocket, emptyIps } = build();
    regexpSocket.post(new noflo.IP("data", "^foo"));
    inSocket.post(new noflo.IP("openBracket", "bar"));
    inSocket.post(new noflo.IP("data", "b"));
    inSocket.post(new noflo.IP("closeBracket", "bar"));
    assert.equal(emptyIps.length, 1);
    c.tearDown?.();
  });
});

describe("Objectify component", () => {
  /** @returns {{ c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, regexpSocket: import("@noflo/noflo").internalSocket.InternalSocket, outIps: import("@noflo/noflo").IP[] }} */
  const build = () => {
    const c = getObjectify();
    const inSocket = noflo.internalSocket.createSocket();
    const regexpSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.inPorts.regexp.attach(regexpSocket);
    c.outPorts.out.attach(outSocket);
    return {
      c,
      inSocket,
      regexpSocket,
      outIps: collect(outSocket),
    };
  };

  it("makes an object from matching groups and retains the stream", () => {
    const { c, inSocket, regexpSocket, outIps } = build();
    regexpSocket.post(new noflo.IP("data", "^(a)"));
    inSocket.post(new noflo.IP("openBracket", "abc"));
    inSocket.post(new noflo.IP("data", "whatever"));
    inSocket.post(new noflo.IP("closeBracket", "abc"));
    assert.deepEqual(render(outIps), ["< abc", 'DATA {"a":"whatever"}', ">"]);
    c.tearDown?.();
  });

  it("passes non-matching groups through as-is", () => {
    const { c, inSocket, regexpSocket, outIps } = build();
    regexpSocket.post(new noflo.IP("data", "^(a)"));
    inSocket.post(new noflo.IP("openBracket", "xyz"));
    inSocket.post(new noflo.IP("data", "whatever"));
    inSocket.post(new noflo.IP("closeBracket", "xyz"));
    assert.deepEqual(render(outIps), ["< xyz", 'DATA "whatever"', ">"]);
    c.tearDown?.();
  });
});

describe("Regroup component", () => {
  /** @returns {{ c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, groupSocket: import("@noflo/noflo").internalSocket.InternalSocket, outIps: import("@noflo/noflo").IP[] }} */
  const build = () => {
    const c = getRegroup();
    const inSocket = noflo.internalSocket.createSocket();
    const groupSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.inPorts.group.attach(groupSocket);
    c.outPorts.out.attach(outSocket);
    return {
      c,
      inSocket,
      groupSocket,
      outIps: collect(outSocket),
    };
  };

  it("removes all groups when no replacement groups are given", () => {
    const { c, inSocket, outIps } = build();
    inSocket.post(new noflo.IP("openBracket", "group"));
    inSocket.post(new noflo.IP("data", "data"));
    inSocket.post(new noflo.IP("closeBracket", "group"));
    assert.deepEqual(render(outIps), ['DATA "data"']);
    c.tearDown?.();
  });

  it("replaces the groups around the packet", () => {
    const { c, inSocket, groupSocket, outIps } = build();
    groupSocket.post(new noflo.IP("data", "group1"));
    groupSocket.post(new noflo.IP("data", "group2"));
    groupSocket.post(new noflo.IP("data", "group3"));
    inSocket.post(new noflo.IP("openBracket", "group"));
    inSocket.post(new noflo.IP("data", "data"));
    inSocket.post(new noflo.IP("closeBracket", "group"));
    assert.deepEqual(render(outIps), [
      "< group1",
      "< group2",
      "< group3",
      'DATA "data"',
      ">",
      ">",
      ">",
    ]);
    c.tearDown?.();
  });
});

describe("RemoveGroups component", () => {
  /** @returns {{ c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, regexpSocket: import("@noflo/noflo").internalSocket.InternalSocket, outIps: import("@noflo/noflo").IP[] }} */
  const build = (attachRegexp = false) => {
    const c = getRemoveGroups();
    const inSocket = noflo.internalSocket.createSocket();
    const regexpSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    if (attachRegexp) {
      c.inPorts.regexp.attach(regexpSocket);
    }
    c.outPorts.out.attach(outSocket);
    return {
      c,
      inSocket,
      regexpSocket,
      outIps: collect(outSocket),
    };
  };

  it("removes all groups when no regexp is given", () => {
    const { c, inSocket, outIps } = build();
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "bar"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "bar"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(outIps), ['DATA "a"']);
    c.tearDown?.();
  });

  it("removes only matching groups", () => {
    const { c, inSocket, regexpSocket, outIps } = build(true);
    regexpSocket.post(new noflo.IP("data", "^bar"));
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("openBracket", "bar"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "bar"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(outIps), ["< foo", 'DATA "a"', ">"]);
    c.tearDown?.();
  });

  it("keeps groups when they do not match", () => {
    const { c, inSocket, regexpSocket, outIps } = build(true);
    regexpSocket.post(new noflo.IP("data", "^qux"));
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(outIps), ["< foo", 'DATA "a"', ">"]);
    c.tearDown?.();
  });
});
