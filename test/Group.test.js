import assert from "node:assert/strict";
import { describe, it } from "node:test";
import * as noflo from "@noflo/noflo";

import { getComponent as getGenerateGroup } from "../components/GenerateGroup.js";
import { getComponent as getGroup } from "../components/Group.js";
import { getComponent as getGroupByObjectKey } from "../components/GroupByObjectKey.js";
import { getComponent as getGroupZip } from "../components/GroupZip.js";
import { getComponent as getMapGroup } from "../components/MapGroup.js";
import { collect, render } from "./helpers.js";

/** Builds a component with `in`/`group`/`out` wired for probing. */
const buildGroup = () => {
  const c = getGroup();
  const inSocket = noflo.internalSocket.createSocket();
  const groupSocket = noflo.internalSocket.createSocket();
  const outSocket = noflo.internalSocket.createSocket();
  c.inPorts.in.attach(inSocket);
  c.inPorts.group.attach(groupSocket);
  c.outPorts.out.attach(outSocket);
  return { c, inSocket, groupSocket, outSocket };
};

describe("Group component", () => {
  it("sends the packet with a single group", () => {
    const { c, inSocket, groupSocket, outSocket } = buildGroup();
    const ips = collect(outSocket);
    groupSocket.post(new noflo.IP("data", "foo"));
    inSocket.post(new noflo.IP("data", "a"));
    assert.deepEqual(render(ips), ["< foo", 'DATA "a"', ">"]);
    c.tearDown?.(() => {});
  });

  it("sends the packet with nested groups from a colon string", () => {
    const { c, inSocket, groupSocket, outSocket } = buildGroup();
    const ips = collect(outSocket);
    groupSocket.post(new noflo.IP("data", "foo:bar"));
    inSocket.post(new noflo.IP("data", "a"));
    assert.deepEqual(render(ips), ["< foo", "< bar", 'DATA "a"', ">", ">"]);
    c.tearDown?.(() => {});
  });

  it("accepts an array of groups", () => {
    const { c, inSocket, groupSocket, outSocket } = buildGroup();
    const ips = collect(outSocket);
    groupSocket.post(new noflo.IP("data", ["foo", "bar"]));
    inSocket.post(new noflo.IP("data", "a"));
    assert.deepEqual(render(ips), ["< foo", "< bar", 'DATA "a"', ">", ">"]);
    c.tearDown?.(() => {});
  });
});

describe("GroupZip component", () => {
  it("wraps packets in corresponding groups by position", () => {
    const c = getGroupZip();
    const inSocket = noflo.internalSocket.createSocket();
    const groupSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.inPorts.group.attach(groupSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    groupSocket.post(new noflo.IP("data", "foo"));
    inSocket.post(new noflo.IP("data", "a"));
    groupSocket.post(new noflo.IP("data", "bar"));
    inSocket.post(new noflo.IP("data", "b"));
    assert.deepEqual(render(ips), [
      "< foo",
      'DATA "a"',
      ">",
      "< bar",
      'DATA "b"',
      ">",
    ]);
  });
});

describe("GroupByObjectKey component", () => {
  /** @returns {[c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, keySocket: import("@noflo/noflo").internalSocket.InternalSocket, outSocket: import("@noflo/noflo").internalSocket.InternalSocket, errorSocket: import("@noflo/noflo").internalSocket.InternalSocket]} */
  const build = () => {
    const c = getGroupByObjectKey();
    const inSocket = noflo.internalSocket.createSocket();
    const keySocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    const errorSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.inPorts.key.attach(keySocket);
    c.outPorts.out.attach(outSocket);
    c.outPorts.error.attach(errorSocket);
    return [c, inSocket, keySocket, outSocket, errorSocket];
  };

  it("sends the packet with the group from its payload", () => {
    const [c, inSocket, keySocket, outSocket] = build();
    const ips = collect(outSocket);
    keySocket.post(new noflo.IP("data", "name"));
    inSocket.post(new noflo.IP("data", { name: "foo", other: 1 }));
    assert.deepEqual(render(ips), [
      "< foo",
      'DATA {"name":"foo","other":1}',
      ">",
    ]);
    c.tearDown?.(() => {});
  });

  it("sends the packet with an undefined group for non-string values", () => {
    const [c, inSocket, keySocket, outSocket] = build();
    const ips = collect(outSocket);
    keySocket.post(new noflo.IP("data", "name"));
    inSocket.post(new noflo.IP("data", { name: 42 }));
    assert.deepEqual(render(ips), ["< undefined", 'DATA {"name":42}', ">"]);
    c.tearDown?.(() => {});
  });

  it("groups boolean true by the key name", () => {
    const [c, inSocket, keySocket, outSocket] = build();
    const ips = collect(outSocket);
    keySocket.post(new noflo.IP("data", "name"));
    inSocket.post(new noflo.IP("data", { name: true }));
    assert.deepEqual(render(ips), ["< name", 'DATA {"name":true}', ">"]);
    c.tearDown?.(() => {});
  });

  it("groups boolean false as undefined", () => {
    const [c, inSocket, keySocket, outSocket] = build();
    const ips = collect(outSocket);
    keySocket.post(new noflo.IP("data", "name"));
    inSocket.post(new noflo.IP("data", { name: false }));
    assert.deepEqual(render(ips), ["< undefined", 'DATA {"name":false}', ">"]);
    c.tearDown?.(() => {});
  });

  it("sends an error for non-object payloads", () => {
    const [c, inSocket, keySocket, , errorSocket] = build();
    const errors = collect(errorSocket);
    keySocket.post(new noflo.IP("data", "name"));
    inSocket.post(new noflo.IP("data", "not an object"));
    assert.equal(errors.length, 1);
    assert.equal(
      /** @type {Error} */ (errors[0].data).message,
      "Data is not an object",
    );
    c.tearDown?.(() => {});
  });
});

describe("GenerateGroup component", () => {
  it("wraps each packet in a generated UUID group", () => {
    const c = getGenerateGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("data", "b"));
    const rendered = render(ips);
    assert.equal(rendered.length, 6);
    assert.match(rendered[0], /^< [0-9a-f-]{36}$/);
    assert.equal(rendered[1], 'DATA "a"');
    assert.equal(rendered[2], ">");
    assert.match(rendered[3], /^< [0-9a-f-]{36}$/);
    assert.equal(rendered[4], 'DATA "b"');
    assert.equal(rendered[5], ">");
    // Each packet gets its own group identifier
    assert.notEqual(rendered[0], rendered[3]);
  });
});

describe("MapGroup component", () => {
  /**
   * @param {boolean} [attachMap]
   * @param {boolean} [attachRegexp]
   * @returns {{ c: import("@noflo/noflo").Component, inSocket: import("@noflo/noflo").internalSocket.InternalSocket, mapSocket: import("@noflo/noflo").internalSocket.InternalSocket, regexpSocket: import("@noflo/noflo").internalSocket.InternalSocket, outSocket: import("@noflo/noflo").internalSocket.InternalSocket, ips: import("@noflo/noflo").IP[] }}
   */
  const build = (attachMap = false, attachRegexp = false) => {
    const c = getMapGroup();
    const inSocket = noflo.internalSocket.createSocket();
    const mapSocket = noflo.internalSocket.createSocket();
    const regexpSocket = noflo.internalSocket.createSocket();
    const outSocket = noflo.internalSocket.createSocket();
    c.inPorts.in.attach(inSocket);
    if (attachMap) {
      c.inPorts.map.attach(mapSocket);
    }
    if (attachRegexp) {
      c.inPorts.regexp.attach(regexpSocket);
    }
    c.outPorts.out.attach(outSocket);
    const ips = collect(outSocket);
    return { c, inSocket, mapSocket, regexpSocket, outSocket, ips };
  };

  it("sends ungrouped data as-is", () => {
    const { inSocket, ips } = build();
    inSocket.post(new noflo.IP("data", "a"));
    assert.deepEqual(render(ips), ['DATA "a"']);
  });

  it("replaces matched groups with a map string", () => {
    const { inSocket, mapSocket, ips } = build(true);
    mapSocket.post(new noflo.IP("data", "foo=bar"));
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(ips), ["< bar", 'DATA "a"', ">"]);
  });

  it("leaves unmatched groups as-is with a map string", () => {
    const { inSocket, mapSocket, ips } = build(true);
    mapSocket.post(new noflo.IP("data", "foo=bar"));
    inSocket.post(new noflo.IP("openBracket", "baz"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "baz"));
    assert.deepEqual(render(ips), ["< baz", 'DATA "a"', ">"]);
  });

  it("replaces matched groups with a map object", () => {
    const { inSocket, mapSocket, ips } = build(true);
    mapSocket.post(new noflo.IP("data", { foo: "bar", other: "x" }));
    inSocket.post(new noflo.IP("openBracket", "foo"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "foo"));
    assert.deepEqual(render(ips), ["< bar", 'DATA "a"', ">"]);
  });

  it("replaces matched groups with a regexp string", () => {
    const { inSocket, regexpSocket, ips } = build(false, true);
    regexpSocket.post(new noflo.IP("data", "^foo=bar"));
    inSocket.post(new noflo.IP("openBracket", "foobar"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "foobar"));
    assert.deepEqual(render(ips), ["< barbar", 'DATA "a"', ">"]);
  });

  it("applies regexp replacements in object order", () => {
    const { inSocket, regexpSocket, ips } = build(false, true);
    regexpSocket.post(new noflo.IP("data", { "^foo": "bar", bar$: "baz" }));
    inSocket.post(new noflo.IP("openBracket", "foobar"));
    inSocket.post(new noflo.IP("data", "a"));
    inSocket.post(new noflo.IP("closeBracket", "foobar"));
    assert.deepEqual(render(ips), ["< barbaz", 'DATA "a"', ">"]);
  });
});
