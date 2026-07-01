const providers = [
  {
    id: "postnl",
    label: "PostNL",
    category: "shipping",
    authType: "api_key",
    requiredEnv: ["POSTNL_API_KEY", "POSTNL_CUSTOMER_CODE"],
    purpose: "Create labels, track Dutch parcels, and store shipment refs on orders.",
  },
  {
    id: "dhl_express",
    label: "DHL Express",
    category: "shipping",
    authType: "api_key",
    requiredEnv: ["DHL_EXPRESS_API_KEY", "DHL_EXPRESS_ACCOUNT_NUMBER"],
    purpose: "Create international labels, quotes, pickups, and tracking events.",
  },
  {
    id: "fedex",
    label: "FedEx",
    category: "shipping",
    authType: "oauth_client_credentials",
    requiredEnv: ["FEDEX_CLIENT_ID", "FEDEX_CLIENT_SECRET", "FEDEX_ACCOUNT_NUMBER"],
    purpose: "Create FedEx shipments, rates, labels, and delivery updates.",
  },
  {
    id: "shopify",
    label: "Shopify",
    category: "commerce",
    authType: "oauth",
    requiredEnv: ["SHOPIFY_SHOP_DOMAIN", "SHOPIFY_CLIENT_ID", "SHOPIFY_CLIENT_SECRET"],
    scopes: ["read_customers", "write_customers", "read_products", "write_inventory", "read_orders", "write_orders"],
    purpose: "Sync customers, products, inventory, and orders with the webshop.",
  },
  {
    id: "outlook_mail",
    label: "Outlook Mail",
    category: "microsoft_graph",
    authType: "oauth",
    requiredEnv: ["MICROSOFT_TENANT_ID", "MICROSOFT_CLIENT_ID", "MICROSOFT_CLIENT_SECRET"],
    scopes: ["Mail.Read", "Mail.Send"],
    purpose: "Read customer email context and draft/send approved replies.",
  },
  {
    id: "outlook_calendar",
    label: "Outlook Calendar",
    category: "microsoft_graph",
    authType: "oauth",
    requiredEnv: ["MICROSOFT_TENANT_ID", "MICROSOFT_CLIENT_ID", "MICROSOFT_CLIENT_SECRET"],
    scopes: ["Calendars.ReadWrite"],
    purpose: "Schedule eye exams, fittings, pickups, and follow-ups.",
  },
  {
    id: "sharepoint",
    label: "SharePoint",
    category: "microsoft_graph",
    authType: "oauth",
    requiredEnv: ["MICROSOFT_TENANT_ID", "MICROSOFT_CLIENT_ID", "MICROSOFT_CLIENT_SECRET"],
    scopes: ["Sites.ReadWrite.All", "Files.ReadWrite.All"],
    purpose: "Store shared documents, product files, and business records.",
  },
  {
    id: "onedrive",
    label: "OneDrive",
    category: "microsoft_graph",
    authType: "oauth",
    requiredEnv: ["MICROSOFT_TENANT_ID", "MICROSOFT_CLIENT_ID", "MICROSOFT_CLIENT_SECRET"],
    scopes: ["Files.ReadWrite.All"],
    purpose: "Attach customer documents and exported reports to records.",
  },
  {
    id: "teams",
    label: "Teams",
    category: "microsoft_graph",
    authType: "oauth",
    requiredEnv: ["MICROSOFT_TENANT_ID", "MICROSOFT_CLIENT_ID", "MICROSOFT_CLIENT_SECRET"],
    scopes: ["Team.ReadBasic.All", "ChannelMessage.Send"],
    purpose: "Notify staff channels when orders, prescriptions, or shipping states change.",
  },
  {
    id: "enreach",
    label: "Enreach",
    category: "telephony",
    authType: "api_key_or_oauth",
    requiredEnv: ["ENREACH_CLIENT_ID", "ENREACH_CLIENT_SECRET"],
    purpose: "Connect calls, call logs, and customer communication history.",
  },
];

function envConfigured(provider) {
  return provider.requiredEnv.every((name) => Boolean(process.env[name]));
}

function publicProvider(provider) {
  return {
    ...provider,
    configured: envConfigured(provider),
    requiredEnv: provider.requiredEnv.map((name) => ({ name, present: Boolean(process.env[name]) })),
  };
}

module.exports = {
  providers,
  publicProvider,
};
