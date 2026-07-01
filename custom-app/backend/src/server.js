const express = require("express");
const cors = require("cors");
const { providers, publicProvider } = require("./connectors");
const { pool, query, initSchema, getDbStatus } = require("./db");
const { getOpenApiSpec } = require("./openapi");

const app = express();

const PORT = process.env.PORT || 3001;
const OLLAMA_API_BASE_URL = (process.env.OLLAMA_API_BASE_URL || "http://ollama:11434/api").replace(/\/+$/, "");
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || "llama3.2:3b";

let databaseReady = false;
let databaseMessage = "not initialized";

app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/openapi.json", (req, res) => {
  const forwardedProto = req.get("x-forwarded-proto");
  const proto = forwardedProto || req.protocol;
  const host = req.get("host") || `localhost:${PORT}`;
  res.json(getOpenApiSpec(`${proto}://${host}`));
});

function findProvider(providerId) {
  return providers.find((provider) => provider.id === providerId);
}

function requireDatabase(res) {
  if (!pool || !databaseReady) {
    res.status(503).json({
      error: "database unavailable",
      detail: databaseMessage,
    });
    return false;
  }
  return true;
}

function toAddress(body) {
  return {
    line1: body.addressLine1 || body.line1 || "",
    line2: body.addressLine2 || body.line2 || "",
    postalCode: body.postalCode || "",
    city: body.city || "",
    country: body.country || "NL",
  };
}

app.get("/api/health", async (_req, res) => {
  let ollama = { reachable: false, message: "not checked" };

  try {
    const response = await fetch(`${OLLAMA_API_BASE_URL}/tags`, { method: "GET" });
    ollama = { reachable: response.ok, message: response.ok ? "reachable" : `HTTP ${response.status}` };
  } catch (error) {
    ollama = { reachable: false, message: error.message };
  }

  const db = await getDbStatus();
  databaseReady = db.ready;
  databaseMessage = db.message;

  res.json({
    status: ollama.reachable && (!db.configured || db.ready) ? "ok" : "degraded",
    ollama,
    database: db,
    connectors: providers.length,
  });
});

app.get("/api/connectors", async (_req, res) => {
  const configured = providers.map(publicProvider);

  if (!pool || !databaseReady) {
    return res.json({ database: false, connectors: configured });
  }

  const result = await query("select provider, status, auth_type, account_label, scopes, last_sync_at, updated_at from connector_accounts");
  const accounts = new Map(result.rows.map((row) => [row.provider, row]));

  return res.json({
    database: true,
    connectors: configured.map((provider) => ({
      ...provider,
      account: accounts.get(provider.id) || null,
      status: accounts.get(provider.id)?.status || (provider.configured ? "env_ready" : "needs_credentials"),
    })),
  });
});

app.get("/api/agent-capabilities", (_req, res) => {
  res.json({
    capabilities: [
      {
        area: "business_status",
        actions: [
          "Check database health and connector readiness",
          "Summarize customer, prescription, inventory, and order counts",
          "Explain which integrations still need credentials",
        ],
        cautions: ["Do not claim external sync works until the connector status is ready."],
      },
      {
        area: "customer_work",
        actions: [
          "Search customers by name, email, or phone",
          "Create customer records after user confirmation",
          "Open a customer profile with prescription history and external references",
        ],
        cautions: ["Confirm identity before showing or changing customer details."],
      },
      {
        area: "optical_prescriptions",
        actions: [
          "Store OD/OS prescription values",
          "Attach exam date, prescriber, PD, prism, and notes",
          "Retrieve prescription history through a customer profile",
        ],
        cautions: ["Confirm all prescription values before writing medical-adjacent data."],
      },
      {
        area: "inventory",
        actions: [
          "List stock by product type, SKU, quantity, reorder level, and location",
          "Create or update frame, lens, and accessory inventory items",
          "Spot low-stock items from quantity and reorder data",
        ],
        cautions: ["Confirm SKU and quantities before updating stock."],
      },
      {
        area: "browser_automation",
        actions: [
          "Fill allowlisted local web forms through the Playwright sidecar",
          "Submit forms and return the final page URL/title",
        ],
        cautions: ["Only allowlisted hosts are reachable and destructive submissions should be confirmed first."],
      },
    ],
  });
});

app.post("/api/connectors/:provider/sign-in", async (req, res) => {
  const provider = findProvider(req.params.provider);
  if (!provider) {
    return res.status(404).json({ error: "unknown provider" });
  }
  if (!requireDatabase(res)) return;

  const publicInfo = publicProvider(provider);
  const status = publicInfo.configured ? "credentials_configured" : "needs_credentials";
  const accountLabel = req.body.accountLabel || provider.label;
  const scopes = req.body.scopes || provider.scopes || [];

  const result = await query(
    `insert into connector_accounts (provider, status, auth_type, account_label, scopes, metadata, updated_at)
     values ($1, $2, $3, $4, $5::jsonb, $6::jsonb, now())
     on conflict (provider) do update set
       status = excluded.status,
       auth_type = excluded.auth_type,
       account_label = excluded.account_label,
       scopes = excluded.scopes,
       metadata = connector_accounts.metadata || excluded.metadata,
       updated_at = now()
     returning provider, status, auth_type, account_label, scopes, updated_at`,
    [
      provider.id,
      status,
      provider.authType,
      accountLabel,
      JSON.stringify(scopes),
      JSON.stringify({ requestedBy: "local-admin", configuredFromEnv: publicInfo.configured }),
    ],
  );

  res.json({
    connector: result.rows[0],
    nextAction: publicInfo.configured
      ? "Credentials are present. Add the provider API client/OAuth callback implementation next."
      : "Add the missing environment variables, then run this sign-in action again.",
    missingEnv: publicInfo.requiredEnv.filter((item) => !item.present).map((item) => item.name),
  });
});

app.get("/api/customers", async (req, res) => {
  if (!requireDatabase(res)) return;
  const search = String(req.query.search || "").trim();
  const params = [];
  let where = "";

  if (search) {
    params.push(`%${search}%`);
    where = `where first_name || ' ' || last_name ilike $1 or email ilike $1 or phone ilike $1`;
  }

  const result = await query(
    `select id, customer_number, first_name, last_name, email, phone, address, marketing_consent, medical_data_consent, created_at
     from customers ${where}
     order by created_at desc
     limit 100`,
    params,
  );
  res.json({ customers: result.rows });
});

app.post("/api/customers", async (req, res) => {
  if (!requireDatabase(res)) return;
  const firstName = String(req.body.firstName || req.body.first_name || "").trim();
  const lastName = String(req.body.lastName || req.body.last_name || "").trim();

  if (!firstName || !lastName) {
    return res.status(400).json({ error: "firstName and lastName are required" });
  }

  const result = await query(
    `insert into customers (first_name, last_name, email, phone, date_of_birth, address, marketing_consent, medical_data_consent, notes, metadata)
     values ($1, $2, $3, $4, $5, $6::jsonb, $7, $8, $9, $10::jsonb)
     returning *`,
    [
      firstName,
      lastName,
      req.body.email || null,
      req.body.phone || null,
      req.body.dateOfBirth || null,
      JSON.stringify(req.body.address || toAddress(req.body)),
      Boolean(req.body.marketingConsent),
      Boolean(req.body.medicalDataConsent),
      req.body.notes || null,
      JSON.stringify(req.body.metadata || {}),
    ],
  );
  res.status(201).json({ customer: result.rows[0] });
});

app.get("/api/customers/:id", async (req, res) => {
  if (!requireDatabase(res)) return;
  const customer = await query("select * from customers where id = $1", [req.params.id]);
  if (!customer.rowCount) {
    return res.status(404).json({ error: "customer not found" });
  }
  const prescriptions = await query("select * from eye_prescriptions where customer_id = $1 order by exam_date desc", [req.params.id]);
  const externalRefs = await query("select * from customer_external_refs where customer_id = $1 order by created_at desc", [req.params.id]);
  res.json({ customer: customer.rows[0], prescriptions: prescriptions.rows, externalRefs: externalRefs.rows });
});

app.post("/api/customers/:id/prescriptions", async (req, res) => {
  if (!requireDatabase(res)) return;
  const result = await query(
    `insert into eye_prescriptions (
       customer_id, exam_date, prescriber, od_sphere, od_cylinder, od_axis, od_add, od_prism,
       os_sphere, os_cylinder, os_axis, os_add, os_prism, pd_distance, pd_near, notes, attachment_url
     ) values ($1, coalesce($2::date, current_date), $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
     returning *`,
    [
      req.params.id,
      req.body.examDate || null,
      req.body.prescriber || null,
      req.body.odSphere ?? null,
      req.body.odCylinder ?? null,
      req.body.odAxis ?? null,
      req.body.odAdd ?? null,
      req.body.odPrism || null,
      req.body.osSphere ?? null,
      req.body.osCylinder ?? null,
      req.body.osAxis ?? null,
      req.body.osAdd ?? null,
      req.body.osPrism || null,
      req.body.pdDistance ?? null,
      req.body.pdNear ?? null,
      req.body.notes || null,
      req.body.attachmentUrl || null,
    ],
  );
  res.status(201).json({ prescription: result.rows[0] });
});

app.get("/api/inventory", async (_req, res) => {
  if (!requireDatabase(res)) return;
  const result = await query(
    `select id, sku, product_type, name, quantity_on_hand, quantity_reserved, reorder_level, location, metadata, updated_at
     from inventory_items
     order by product_type, name
     limit 250`,
  );
  res.json({ inventory: result.rows });
});

app.post("/api/inventory", async (req, res) => {
  if (!requireDatabase(res)) return;
  const sku = String(req.body.sku || "").trim();
  const productType = String(req.body.productType || req.body.product_type || "").trim();
  const name = String(req.body.name || "").trim();

  if (!sku || !productType || !name) {
    return res.status(400).json({ error: "sku, productType, and name are required" });
  }

  const result = await query(
    `insert into inventory_items (sku, product_type, name, quantity_on_hand, quantity_reserved, reorder_level, location, metadata)
     values ($1, $2, $3, $4, $5, $6, $7, $8::jsonb)
     on conflict (sku) do update set
       name = excluded.name,
       product_type = excluded.product_type,
       quantity_on_hand = excluded.quantity_on_hand,
       quantity_reserved = excluded.quantity_reserved,
       reorder_level = excluded.reorder_level,
       location = excluded.location,
       metadata = inventory_items.metadata || excluded.metadata,
       updated_at = now()
     returning *`,
    [
      sku,
      productType,
      name,
      Number(req.body.quantityOnHand ?? req.body.quantity_on_hand ?? 0),
      Number(req.body.quantityReserved ?? req.body.quantity_reserved ?? 0),
      Number(req.body.reorderLevel ?? req.body.reorder_level ?? 0),
      req.body.location || null,
      JSON.stringify(req.body.metadata || {}),
    ],
  );
  res.status(201).json({ item: result.rows[0] });
});

app.get("/api/business/dashboard", async (_req, res) => {
  const baseConnectors = providers.map(publicProvider);
  if (!pool || !databaseReady) {
    return res.json({
      database: { ready: false, message: databaseMessage },
      counts: { customers: 0, prescriptions: 0, inventory: 0, orders: 0 },
      connectors: baseConnectors.map((provider) => ({ ...provider, status: provider.configured ? "env_ready" : "needs_credentials" })),
    });
  }

  const [counts, accounts] = await Promise.all([
    query(`select
      (select count(*)::int from customers) as customers,
      (select count(*)::int from eye_prescriptions) as prescriptions,
      (select count(*)::int from inventory_items) as inventory,
      (select count(*)::int from orders) as orders`),
    query("select provider, status, last_sync_at from connector_accounts"),
  ]);
  const accountMap = new Map(accounts.rows.map((row) => [row.provider, row]));

  res.json({
    database: { ready: true, message: "reachable" },
    counts: counts.rows[0],
    connectors: baseConnectors.map((provider) => ({
      ...provider,
      status: accountMap.get(provider.id)?.status || (provider.configured ? "env_ready" : "needs_credentials"),
      lastSyncAt: accountMap.get(provider.id)?.last_sync_at || null,
    })),
  });
});

app.post("/api/chat", async (req, res) => {
  const message = (req.body && req.body.message ? String(req.body.message) : "").trim();

  if (!message) {
    return res.status(400).json({ error: "message is required" });
  }

  try {
    const response = await fetch(`${OLLAMA_API_BASE_URL}/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: req.body.model || OLLAMA_MODEL,
        stream: false,
        messages: [{ role: "user", content: message }],
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      return res.status(502).json({ error: "ollama request failed", detail: body });
    }

    const data = await response.json();
    const answer = data && data.message && data.message.content ? data.message.content : "";

    return res.json({
      model: data.model || req.body.model || OLLAMA_MODEL,
      response: answer,
      raw: data,
    });
  } catch (error) {
    return res.status(500).json({ error: "chat failed", detail: error.message });
  }
});

async function start() {
  try {
    const status = await initSchema();
    databaseReady = status.ready;
    databaseMessage = status.message;
  } catch (error) {
    databaseReady = false;
    databaseMessage = error.message;
    console.error(`database init failed: ${error.message}`);
  }

  app.listen(PORT, () => {
    console.log(`custom-chatbot-backend listening on port ${PORT}`);
  });
}

start();
