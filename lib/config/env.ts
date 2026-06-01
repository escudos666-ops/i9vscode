export const env = {
  ollamaUrl: process.env.OLLAMA_URL ?? "http://localhost:11434",
  ollamaModel: process.env.OLLAMA_MODEL ?? "llama3.2",

  outlookTenantId: process.env.OUTLOOK_TENANT_ID ?? "",
  outlookClientId: process.env.OUTLOOK_CLIENT_ID ?? "",
  outlookClientSecret: process.env.OUTLOOK_CLIENT_SECRET ?? "",

  shopifyStore: process.env.SHOPIFY_STORE ?? "",
  shopifyAdminToken: process.env.SHOPIFY_ADMIN_TOKEN ?? "",

  wahaUrl: process.env.WAHA_URL ?? "http://localhost:3001",
  wahaApiKey: process.env.WAHA_API_KEY ?? "",
  wahaSession: process.env.WAHA_SESSION ?? "default",

  appDbPath: process.env.APP_DB_PATH ?? "./data/app-db.json"
};