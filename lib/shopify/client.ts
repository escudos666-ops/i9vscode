import { env } from "@/lib/config/env";

export async function getShopifyOrders() {
  if (!env.shopifyStore || !env.shopifyAdminToken) {
    return {
      ok: false,
      configured: false,
      orders: [],
      note: "Add SHOPIFY_STORE and SHOPIFY_ADMIN_TOKEN to .env.local, then restart npm run dev."
    };
  }

  const response = await fetch(
    `https://${env.shopifyStore}/admin/api/2024-10/orders.json?status=any&limit=10`,
    {
      headers: {
        "X-Shopify-Access-Token": env.shopifyAdminToken,
        "Content-Type": "application/json"
      },
      cache: "no-store"
    }
  );

  const data = await response.json();

  return {
    ok: response.ok,
    configured: true,
    orders: data.orders ?? [],
    raw: data
  };
}