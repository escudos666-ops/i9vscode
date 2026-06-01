import { getShopifyOrders } from "@/lib/shopify/client";

export async function GET() {
  const result = await getShopifyOrders();
  return Response.json(result);
}