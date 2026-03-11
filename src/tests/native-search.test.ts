import test from "node:test";
import assert from "node:assert/strict";
import {
  registerNativeSearchHooks,
  BRAVE_TOOL_NAMES,
  type NativeSearchPI,
} from "../resources/extensions/search-the-web/native-search.ts";

/**
 * Tests for native Anthropic web search injection.
 *
 * Tests the hook logic in native-search.ts directly (no heavy tool deps).
 */

// ─── Mock ExtensionAPI ──────────────────────────────────────────────────────

interface MockHandler {
  event: string;
  handler: (...args: any[]) => any;
}

function createMockPI() {
  const handlers: MockHandler[] = [];
  let activeTools = ["search-the-web", "search_and_read", "fetch_page", "bash", "read"];
  const notifications: Array<{ message: string; level: string }> = [];

  const mockCtx = {
    ui: {
      notify(message: string, level: string) {
        notifications.push({ message, level });
      },
    },
  };

  const pi: NativeSearchPI & {
    handlers: MockHandler[];
    notifications: typeof notifications;
    mockCtx: typeof mockCtx;
    fire(event: string, eventData: any, ctx?: any): Promise<any>;
  } = {
    handlers,
    notifications,
    mockCtx,
    on(event: string, handler: (...args: any[]) => any) {
      handlers.push({ event, handler });
    },
    getActiveTools() {
      return [...activeTools];
    },
    setActiveTools(tools: string[]) {
      activeTools = tools;
    },
    async fire(event: string, eventData: any, ctx?: any) {
      for (const h of handlers) {
        if (h.event === event) {
          return await h.handler(eventData, ctx ?? mockCtx);
        }
      }
    },
  };

  return pi;
}

// ─── Tests ──────────────────────────────────────────────────────────────────

test("before_provider_request injects web_search for claude models", async () => {
  const pi = createMockPI();
  registerNativeSearchHooks(pi);

  const payload: Record<string, unknown> = {
    model: "claude-sonnet-4-6-20250514",
    tools: [{ name: "bash", type: "custom" }],
  };

  const result = await pi.fire("before_provider_request", {
    type: "before_provider_request",
    payload,
  });

  const tools = (result as any)?.tools ?? payload.tools;
  const hasNative = (tools as any[]).some(
    (t: any) => t.type === "web_search_20250305"
  );
  assert.ok(hasNative, "Should inject web_search_20250305 tool");
  assert.equal((tools as any[]).length, 2, "Should have original + injected tool");
});

test("before_provider_request does NOT inject for non-claude models", async () => {
  const pi = createMockPI();
  registerNativeSearchHooks(pi);

  const payload: Record<string, unknown> = {
    model: "gpt-4o",
    tools: [{ name: "bash", type: "custom" }],
  };

  const result = await pi.fire("before_provider_request", {
    type: "before_provider_request",
    payload,
  });

  assert.equal(result, undefined, "Should not modify non-claude payload");
  const tools = payload.tools as any[];
  assert.equal(tools.length, 1, "Should not add tools to non-claude payload");
});

test("before_provider_request does not double-inject", async () => {
  const pi = createMockPI();
  registerNativeSearchHooks(pi);

  const payload: Record<string, unknown> = {
    model: "claude-opus-4-6-20250514",
    tools: [{ type: "web_search_20250305", name: "web_search" }],
  };

  const result = await pi.fire("before_provider_request", {
    type: "before_provider_request",
    payload,
  });

  assert.equal(result, undefined, "Should not modify when already injected");
  const tools = payload.tools as any[];
  assert.equal(tools.length, 1, "Should not duplicate web_search tool");
});

test("before_provider_request creates tools array if missing", async () => {
  const pi = createMockPI();
  registerNativeSearchHooks(pi);

  const payload: Record<string, unknown> = {
    model: "claude-haiku-4-5-20251001",
  };

  const result = await pi.fire("before_provider_request", {
    type: "before_provider_request",
    payload,
  });

  const tools = (result as any)?.tools ?? payload.tools;
  assert.ok(Array.isArray(tools), "Should create tools array");
  assert.equal((tools as any[]).length, 1, "Should have exactly 1 tool");
  assert.equal((tools as any[])[0].type, "web_search_20250305");
});

test("before_provider_request skips when payload is falsy", async () => {
  const pi = createMockPI();
  registerNativeSearchHooks(pi);

  const result = await pi.fire("before_provider_request", {
    type: "before_provider_request",
    payload: null,
  });

  assert.equal(result, undefined, "Should return undefined for null payload");
});

test("model_select disables Brave tools when Anthropic + no BRAVE_API_KEY", async () => {
  const originalKey = process.env.BRAVE_API_KEY;
  delete process.env.BRAVE_API_KEY;

  try {
    const pi = createMockPI();
    registerNativeSearchHooks(pi);

    await pi.fire("model_select", {
      type: "model_select",
      model: { provider: "anthropic", name: "claude-sonnet-4-6" },
      previousModel: undefined,
      source: "set",
    });

    const active = pi.getActiveTools();
    assert.ok(!active.includes("search-the-web"), "search-the-web should be disabled");
    assert.ok(!active.includes("search_and_read"), "search_and_read should be disabled");
    assert.ok(active.includes("fetch_page"), "fetch_page should remain active");
    assert.ok(active.includes("bash"), "Other tools should remain active");
  } finally {
    if (originalKey) process.env.BRAVE_API_KEY = originalKey;
    else delete process.env.BRAVE_API_KEY;
  }
});

test("model_select keeps Brave tools when BRAVE_API_KEY is set", async () => {
  const originalKey = process.env.BRAVE_API_KEY;
  process.env.BRAVE_API_KEY = "test-key";

  try {
    const pi = createMockPI();
    registerNativeSearchHooks(pi);

    await pi.fire("model_select", {
      type: "model_select",
      model: { provider: "anthropic", name: "claude-sonnet-4-6" },
      previousModel: undefined,
      source: "set",
    });

    const active = pi.getActiveTools();
    assert.ok(active.includes("search-the-web"), "search-the-web should stay active");
    assert.ok(active.includes("search_and_read"), "search_and_read should stay active");
  } finally {
    if (originalKey) process.env.BRAVE_API_KEY = originalKey;
    else delete process.env.BRAVE_API_KEY;
  }
});

test("model_select re-enables Brave tools when switching away from Anthropic", async () => {
  const originalKey = process.env.BRAVE_API_KEY;
  delete process.env.BRAVE_API_KEY;

  try {
    const pi = createMockPI();
    registerNativeSearchHooks(pi);

    // First: select Anthropic — disables Brave tools
    await pi.fire("model_select", {
      type: "model_select",
      model: { provider: "anthropic", name: "claude-sonnet-4-6" },
      previousModel: undefined,
      source: "set",
    });

    let active = pi.getActiveTools();
    assert.ok(!active.includes("search-the-web"), "Should disable after Anthropic select");

    // Second: switch to non-Anthropic — re-enables
    await pi.fire("model_select", {
      type: "model_select",
      model: { provider: "openai", name: "gpt-4o" },
      previousModel: { provider: "anthropic", name: "claude-sonnet-4-6" },
      source: "set",
    });

    active = pi.getActiveTools();
    assert.ok(active.includes("search-the-web"), "search-the-web should be re-enabled");
    assert.ok(active.includes("search_and_read"), "search_and_read should be re-enabled");
  } finally {
    if (originalKey) process.env.BRAVE_API_KEY = originalKey;
    else delete process.env.BRAVE_API_KEY;
  }
});

test("session_start shows 'Native search' when Anthropic provider", async () => {
  const pi = createMockPI();
  registerNativeSearchHooks(pi);

  // Simulate an Anthropic request so isAnthropicProvider becomes true
  await pi.fire("before_provider_request", {
    type: "before_provider_request",
    payload: { model: "claude-sonnet-4-6-20250514", tools: [] },
  });

  await pi.fire("session_start", { type: "session_start" });

  const infoNotif = pi.notifications.find(
    (n) => n.level === "info" && n.message.includes("v4")
  );
  assert.ok(infoNotif, "Should have v4 info notification");
  assert.ok(
    infoNotif!.message.includes("Native search"),
    `Should include 'Native search' — got: ${infoNotif!.message}`
  );
});

test("session_start shows warning when no Anthropic and no Brave key", async () => {
  const originalKey = process.env.BRAVE_API_KEY;
  delete process.env.BRAVE_API_KEY;

  try {
    const pi = createMockPI();
    registerNativeSearchHooks(pi);

    // Don't fire any model/request events — isAnthropicProvider stays false
    await pi.fire("session_start", { type: "session_start" });

    const warning = pi.notifications.find((n) => n.level === "warning");
    assert.ok(warning, "Should show warning when no Anthropic and no Brave key");
    assert.ok(
      warning!.message.includes("Anthropic"),
      `Warning should mention Anthropic — got: ${warning!.message}`
    );
  } finally {
    if (originalKey) process.env.BRAVE_API_KEY = originalKey;
    else delete process.env.BRAVE_API_KEY;
  }
});

test("session_start does NOT show warning when Brave key present", async () => {
  const originalKey = process.env.BRAVE_API_KEY;
  process.env.BRAVE_API_KEY = "test-key";

  try {
    const pi = createMockPI();
    registerNativeSearchHooks(pi);

    await pi.fire("session_start", { type: "session_start" });

    const warning = pi.notifications.find((n) => n.level === "warning");
    assert.equal(warning, undefined, "Should NOT show warning when Brave key is present");

    const info = pi.notifications.find((n) => n.level === "info");
    assert.ok(info!.message.includes("Brave"), "Should mention Brave in status");
  } finally {
    if (originalKey) process.env.BRAVE_API_KEY = originalKey;
    else delete process.env.BRAVE_API_KEY;
  }
});

test("BRAVE_TOOL_NAMES contains expected tool names", () => {
  assert.deepEqual(BRAVE_TOOL_NAMES, ["search-the-web", "search_and_read"]);
});
