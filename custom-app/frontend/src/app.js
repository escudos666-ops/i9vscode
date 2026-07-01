const form = document.getElementById("chat-form");
const promptInput = document.getElementById("prompt");
const sendButton = document.getElementById("send");
const messages = document.getElementById("messages");
const selectedTitle = document.getElementById("selected-title");
const selectedCopy = document.getElementById("selected-copy");
const runFlowButton = document.getElementById("run-flow");
const newNodeButton = document.getElementById("new-node");
const resetCanvasButton = document.getElementById("reset-canvas");
const zoomLabel = document.getElementById("zoom-label");
const canvas = document.getElementById("canvas");
const connectorList = document.getElementById("connector-list");
const databaseCounts = document.getElementById("database-counts");
const databaseState = document.getElementById("database-state");
const databaseMeta = document.getElementById("database-meta");

let zoom = 100;
let nodeCount = 8;
const customNodePositions = [
  { x: 258, y: 34 },
  { x: 602, y: 34 },
  { x: 268, y: 500 },
  { x: 520, y: 500 },
];

function appendMessage(role, text) {
  const el = document.createElement("article");
  el.className = `message ${role}`;
  el.textContent = text;
  messages.appendChild(el);
  messages.scrollTop = messages.scrollHeight;
}

function selectNode(node) {
  document.querySelectorAll(".node").forEach((item) => item.classList.remove("selected"));
  node.classList.add("selected");
  selectedTitle.textContent = node.dataset.node || node.querySelector("h3").textContent;
  selectedCopy.textContent = node.querySelector("p").textContent;
}

function bindNode(node) {
  node.addEventListener("click", () => selectNode(node));
}

function statusLabel(connector) {
  if (connector.status === "credentials_configured") return "ready";
  if (connector.status === "env_ready") return "env ready";
  if (connector.configured) return "configured";
  return "needs keys";
}

function renderConnectors(connectors) {
  connectorList.innerHTML = "";

  connectors.forEach((connector) => {
    const row = document.createElement("article");
    const isReady = connector.configured || connector.status === "credentials_configured" || connector.status === "env_ready";
    row.className = `connector-row ${isReady ? "ready-row" : "needs-row"}`;
    row.innerHTML = `
      <div>
        <strong>${connector.label}</strong>
        <small>${connector.category} • ${connector.authType}</small>
      </div>
      <button type="button" data-provider="${connector.id}">${statusLabel(connector)}</button>
    `;
    row.querySelector("button").addEventListener("click", () => signInConnector(connector.id));
    connectorList.appendChild(row);
  });
}

function renderCounts(counts) {
  databaseCounts.innerHTML = `
    <span><strong>${counts.customers || 0}</strong> customers</span>
    <span><strong>${counts.prescriptions || 0}</strong> prescriptions</span>
    <span><strong>${counts.inventory || 0}</strong> inventory</span>
    <span><strong>${counts.orders || 0}</strong> orders</span>
  `;
}

async function loadDashboard() {
  try {
    const response = await fetch("/api/business/dashboard");
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();

    renderCounts(data.counts || {});
    renderConnectors(data.connectors || []);

    if (data.database && data.database.ready) {
      databaseState.textContent = "ready";
      databaseState.className = "node-state ready";
      databaseMeta.textContent = "schema: customers + inventory + connectors";
      appendMessage("assistant", "Database schema is reachable and the connector registry is loaded.");
    } else {
      databaseState.textContent = "needs db";
      databaseState.className = "node-state idle";
      databaseMeta.textContent = data.database?.message || "DATABASE_URL missing";
      appendMessage("assistant", `Database not ready yet: ${databaseMeta.textContent}`);
    }
  } catch (error) {
    databaseState.textContent = "offline";
    databaseState.className = "node-state idle";
    databaseMeta.textContent = error.message;
    appendMessage("assistant", `Could not load business dashboard: ${error.message}`);
  }
}

async function signInConnector(provider) {
  appendMessage("assistant", `Creating connector account record for ${provider}...`);
  try {
    const response = await fetch(`/api/connectors/${provider}/sign-in`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ accountLabel: provider }),
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(data.error || `HTTP ${response.status}`);

    appendMessage("assistant", `${provider}: ${data.connector.status}. ${data.nextAction}`);
    if (data.missingEnv && data.missingEnv.length) {
      appendMessage("assistant", `Missing env: ${data.missingEnv.join(", ")}`);
    }
    await loadDashboard();
  } catch (error) {
    appendMessage("assistant", `Connector sign-in failed: ${error.message}`);
  }
}

document.querySelectorAll(".node").forEach(bindNode);

document.querySelectorAll(".tool-button").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".tool-button").forEach((item) => item.classList.remove("active"));
    button.classList.add("active");
    const tool = button.dataset.tool;

    if (tool === "run" || tool === "sync") {
      runFlow();
      return;
    }

    appendMessage("assistant", `Tool mode switched to ${tool}.`);
  });
});

async function runFlow() {
  runFlowButton.disabled = true;
  appendMessage("assistant", "Checking business wiring: bot -> connectors -> Postgres -> optical inventory.");

  const states = [
    ["Open WebUI bot", "Bot can route staff tasks through tools."],
    ["Browser forms", "Browser automation service remains available for form filling."],
    ["Connector hub", "Connector registry exposes sign-in and credential status."],
    ["Customer database", "Postgres stores customer, prescription, inventory and sync records."],
    ["Optical inventory", "Frames and lenses are separated from stock counts."],
  ];

  for (const [nodeName, note] of states) {
    const node = [...document.querySelectorAll(".node")].find((item) => item.dataset.node === nodeName);
    if (node) {
      selectNode(node);
      const state = node.querySelector(".node-state");
      state.textContent = "checking";
      state.className = "node-state idle";
    }
    appendMessage("assistant", note);
    await new Promise((resolve) => setTimeout(resolve, 300));
    if (node) {
      const state = node.querySelector(".node-state");
      state.textContent = "wired";
      state.className = "node-state ready";
    }
  }

  await loadDashboard();
  appendMessage("assistant", "Canvas check complete. Missing provider secrets are expected until you add real API/OAuth credentials.");
  runFlowButton.disabled = false;
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  const prompt = promptInput.value.trim();
  if (!prompt) {
    return;
  }

  appendMessage("user", prompt);
  promptInput.value = "";
  sendButton.disabled = true;
  sendButton.textContent = "Sending";

  try {
    const response = await fetch("/api/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: prompt }),
    });

    if (!response.ok) {
      const errorBody = await response.json().catch(() => ({}));
      throw new Error(errorBody.error || `HTTP ${response.status}`);
    }

    const data = await response.json();
    appendMessage("assistant", data.response || "(empty response)");
  } catch (error) {
    appendMessage("assistant", `Local UI note: ${error.message}. The business canvas and connector controls stay usable.`);
  } finally {
    sendButton.disabled = false;
    sendButton.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M22 2 11 13"/><path d="m22 2-7 20-4-9-9-4Z"/></svg>Send';
    promptInput.focus();
  }
});

newNodeButton.addEventListener("click", () => {
  nodeCount += 1;
  const node = document.createElement("article");
  const nextPosition = customNodePositions[(nodeCount - 9) % customNodePositions.length];
  node.className = "node";
  node.dataset.node = `Custom connector ${nodeCount}`;
  node.style.setProperty("--x", `${nextPosition.x}px`);
  node.style.setProperty("--y", `${nextPosition.y}px`);
  node.innerHTML = `
    <div class="node-head">
      <span class="node-type">Custom</span>
      <span class="node-state idle">planned</span>
    </div>
    <h3>Custom connector ${nodeCount}</h3>
    <p>Define provider auth, sync direction, database target and approval rules.</p>
    <div class="node-meta">created locally</div>
  `;
  canvas.appendChild(node);
  bindNode(node);
  selectNode(node);
  appendMessage("assistant", `Added custom connector ${nodeCount}.`);
});

resetCanvasButton.addEventListener("click", () => {
  zoom = 100;
  zoomLabel.textContent = "Zoom 100%";
  document.querySelectorAll(".node").forEach((node) => {
    const state = node.querySelector(".node-state");
    if (state.id === "database-state") return;
    state.textContent = state.classList.contains("live") ? "local" : "wired";
    state.className = "node-state ready";
  });
  appendMessage("assistant", "Canvas view reset.");
});

runFlowButton.addEventListener("click", runFlow);

promptInput.addEventListener("keydown", (event) => {
  if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
    form.requestSubmit();
  }
});

loadDashboard();
