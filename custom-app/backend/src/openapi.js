function getOpenApiSpec(baseUrl = "http://localhost:3001") {
  return {
    openapi: "3.0.3",
    info: {
      title: "AI LLM Agentic Business Tools",
      version: "0.1.0",
      description:
        "Tool-ready API for Open WebUI agents to inspect connectors, work with optical customers, prescriptions, inventory, and business status.",
    },
    servers: [{ url: baseUrl }],
    tags: [
      { name: "Capabilities", description: "Discover what this tool server can do." },
      { name: "Business", description: "Read business dashboard and connector readiness." },
      { name: "Customers", description: "Find, create, and inspect customer records." },
      { name: "Prescriptions", description: "Create optical prescription records for customers." },
      { name: "Inventory", description: "Read and update optical inventory." },
    ],
    paths: {
      "/api/agent-capabilities": {
        get: {
          tags: ["Capabilities"],
          operationId: "list_agentic_capabilities",
          summary: "List available agentic business capabilities",
          description:
            "Use this first when the user asks what the agent can do with the connected business system.",
          responses: {
            200: {
              description: "Available agentic capabilities",
              content: {
                "application/json": {
                  schema: { $ref: "#/components/schemas/CapabilitiesResponse" },
                },
              },
            },
          },
        },
      },
      "/api/business/dashboard": {
        get: {
          tags: ["Business"],
          operationId: "get_business_dashboard",
          summary: "Get business dashboard counts and connector readiness",
          description:
            "Use this to understand whether the database and external connectors are ready before taking action.",
          responses: {
            200: {
              description: "Business dashboard",
              content: {
                "application/json": {
                  schema: { type: "object", additionalProperties: true },
                },
              },
            },
          },
        },
      },
      "/api/connectors": {
        get: {
          tags: ["Business"],
          operationId: "list_connectors",
          summary: "List configured external connectors",
          description:
            "Use this before promising actions that depend on shipping, Shopify, Microsoft, Teams, SharePoint, OneDrive, or Enreach.",
          responses: {
            200: {
              description: "Connector readiness",
              content: {
                "application/json": {
                  schema: { type: "object", additionalProperties: true },
                },
              },
            },
          },
        },
      },
      "/api/customers": {
        get: {
          tags: ["Customers"],
          operationId: "search_customers",
          summary: "Search customers",
          description:
            "Search customers by name, email, or phone. Use this before creating a customer to avoid duplicates.",
          parameters: [
            {
              name: "search",
              in: "query",
              required: false,
              schema: { type: "string" },
              description: "Name, email, or phone fragment to search for.",
            },
          ],
          responses: {
            200: {
              description: "Matching customers",
              content: {
                "application/json": {
                  schema: { type: "object", additionalProperties: true },
                },
              },
            },
          },
        },
        post: {
          tags: ["Customers"],
          operationId: "create_customer",
          summary: "Create a customer",
          description:
            "Create a customer after confirming the user has supplied first and last name. Ask before storing sensitive medical details.",
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: { $ref: "#/components/schemas/CreateCustomerRequest" },
              },
            },
          },
          responses: {
            201: {
              description: "Created customer",
              content: {
                "application/json": {
                  schema: { type: "object", additionalProperties: true },
                },
              },
            },
            400: { description: "Missing required fields" },
          },
        },
      },
      "/api/customers/{id}": {
        get: {
          tags: ["Customers"],
          operationId: "get_customer_profile",
          summary: "Get customer profile with prescriptions and external refs",
          description:
            "Use this after search_customers when the user asks for customer details, prescription history, or linked external records.",
          parameters: [
            {
              name: "id",
              in: "path",
              required: true,
              schema: { type: "string", format: "uuid" },
              description: "Customer UUID.",
            },
          ],
          responses: {
            200: {
              description: "Customer profile",
              content: {
                "application/json": {
                  schema: { type: "object", additionalProperties: true },
                },
              },
            },
            404: { description: "Customer not found" },
          },
        },
      },
      "/api/customers/{id}/prescriptions": {
        post: {
          tags: ["Prescriptions"],
          operationId: "create_eye_prescription",
          summary: "Create an eye prescription for a customer",
          description:
            "Create an optical prescription record. Confirm values with the user before calling this tool because it stores medical-adjacent data.",
          parameters: [
            {
              name: "id",
              in: "path",
              required: true,
              schema: { type: "string", format: "uuid" },
              description: "Customer UUID.",
            },
          ],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: { $ref: "#/components/schemas/CreatePrescriptionRequest" },
              },
            },
          },
          responses: {
            201: {
              description: "Created prescription",
              content: {
                "application/json": {
                  schema: { type: "object", additionalProperties: true },
                },
              },
            },
          },
        },
      },
      "/api/inventory": {
        get: {
          tags: ["Inventory"],
          operationId: "list_inventory",
          summary: "List inventory items",
          description:
            "Use this to answer stock, reorder, product type, and location questions.",
          responses: {
            200: {
              description: "Inventory items",
              content: {
                "application/json": {
                  schema: { type: "object", additionalProperties: true },
                },
              },
            },
          },
        },
        post: {
          tags: ["Inventory"],
          operationId: "upsert_inventory_item",
          summary: "Create or update an inventory item",
          description:
            "Create or update stock by SKU. Confirm SKU, product type, product name, and quantity before writing.",
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: { $ref: "#/components/schemas/UpsertInventoryRequest" },
              },
            },
          },
          responses: {
            201: {
              description: "Created or updated item",
              content: {
                "application/json": {
                  schema: { type: "object", additionalProperties: true },
                },
              },
            },
            400: { description: "Missing required fields" },
          },
        },
      },
    },
    components: {
      schemas: {
        CapabilitiesResponse: {
          type: "object",
          properties: {
            capabilities: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  area: { type: "string" },
                  actions: { type: "array", items: { type: "string" } },
                  cautions: { type: "array", items: { type: "string" } },
                },
              },
            },
          },
        },
        CreateCustomerRequest: {
          type: "object",
          required: ["firstName", "lastName"],
          properties: {
            firstName: { type: "string" },
            lastName: { type: "string" },
            email: { type: "string" },
            phone: { type: "string" },
            dateOfBirth: { type: "string", format: "date" },
            address: {
              type: "object",
              additionalProperties: true,
              properties: {
                line1: { type: "string" },
                line2: { type: "string" },
                postalCode: { type: "string" },
                city: { type: "string" },
                country: { type: "string", default: "NL" },
              },
            },
            marketingConsent: { type: "boolean" },
            medicalDataConsent: { type: "boolean" },
            notes: { type: "string" },
            metadata: { type: "object", additionalProperties: true },
          },
        },
        CreatePrescriptionRequest: {
          type: "object",
          properties: {
            examDate: { type: "string", format: "date" },
            prescriber: { type: "string" },
            odSphere: { type: "number" },
            odCylinder: { type: "number" },
            odAxis: { type: "integer", minimum: 0, maximum: 180 },
            odAdd: { type: "number" },
            odPrism: { type: "string" },
            osSphere: { type: "number" },
            osCylinder: { type: "number" },
            osAxis: { type: "integer", minimum: 0, maximum: 180 },
            osAdd: { type: "number" },
            osPrism: { type: "string" },
            pdDistance: { type: "number" },
            pdNear: { type: "number" },
            notes: { type: "string" },
            attachmentUrl: { type: "string" },
          },
        },
        UpsertInventoryRequest: {
          type: "object",
          required: ["sku", "productType", "name"],
          properties: {
            sku: { type: "string" },
            productType: { type: "string", enum: ["frame", "lens", "accessory"] },
            name: { type: "string" },
            quantityOnHand: { type: "integer", minimum: 0 },
            quantityReserved: { type: "integer", minimum: 0 },
            reorderLevel: { type: "integer", minimum: 0 },
            location: { type: "string" },
            metadata: { type: "object", additionalProperties: true },
          },
        },
      },
    },
  };
}

module.exports = {
  getOpenApiSpec,
};
