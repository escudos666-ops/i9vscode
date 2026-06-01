import { env } from "@/lib/config/env";

async function getOutlookToken() {
  if (!env.outlookTenantId || !env.outlookClientId || !env.outlookClientSecret) {
    return null;
  }

  const body = new URLSearchParams({
    client_id: env.outlookClientId,
    client_secret: env.outlookClientSecret,
    scope: "https://graph.microsoft.com/.default",
    grant_type: "client_credentials"
  });

  const response = await fetch(
    `https://login.microsoftonline.com/${env.outlookTenantId}/oauth2/v2.0/token`,
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body
    }
  );

  if (!response.ok) throw new Error(`Outlook token failed: HTTP ${response.status}`);

  const data = await response.json();
  return String(data.access_token);
}

export async function getOutlookMessages(userEmail = "me") {
  const token = await getOutlookToken();

  if (!token) {
    return {
      ok: false,
      configured: false,
      messages: [],
      note: "Add OUTLOOK_TENANT_ID, OUTLOOK_CLIENT_ID and OUTLOOK_CLIENT_SECRET to .env.local, then restart npm run dev."
    };
  }

  const response = await fetch(
    `https://graph.microsoft.com/v1.0/users/${userEmail}/messages?$top=10`,
    {
      headers: { Authorization: `Bearer ${token}` },
      cache: "no-store"
    }
  );

  const data = await response.json();

  return {
    ok: response.ok,
    configured: true,
    messages: data.value ?? [],
    raw: data
  };
}