# Optical Connector Canvas

This canvas shows how the Open WebUI bot, browser automation, connectors, and Postgres customer memory are wired.

```mermaid
flowchart LR
  Staff["Staff / User"] --> WebUI["Open WebUI Bot"]
  WebUI --> Browser["Browser Automation\nform filling"]
  WebUI --> Hub["Connector Sign-In Hub"]
  WebUI --> DB["Postgres Customer Memory"]

  Hub --> Ship["Shipping Providers"]
  Ship --> PostNL["PostNL"]
  Ship --> DHL["DHL Express"]
  Ship --> FedEx["FedEx"]

  Hub --> Commerce["Commerce"]
  Commerce --> Shopify["Shopify"]

  Hub --> Microsoft["Microsoft Graph"]
  Microsoft --> Mail["Outlook Mail"]
  Microsoft --> Calendar["Outlook Calendar"]
  Microsoft --> SharePoint["SharePoint"]
  Microsoft --> OneDrive["OneDrive"]
  Microsoft --> Teams["Teams"]

  Hub --> Voice["Telephony"]
  Voice --> Enreach["Enreach"]

  DB --> Customers["Customers"]
  DB --> Prescriptions["Eye Prescriptions"]
  DB --> Frames["Eyewear Frames"]
  DB --> Lenses["Eyewear Lenses"]
  DB --> Inventory["Inventory Items"]
  DB --> Orders["Orders"]
  DB --> Shipments["Shipments"]
  DB --> Events["Integration Events"]
```

## Connector Status Model

- `needs_credentials`: the connector exists in the app, but required env vars are missing.
- `env_ready`: required env vars are present, but no connector account row has been created yet.
- `credentials_configured`: connector account row exists and required env vars were present at sign-in time.

## Database Entities

```mermaid
erDiagram
  customers ||--o{ eye_prescriptions : has
  customers ||--o{ customer_external_refs : maps_to
  customers ||--o{ orders : places
  orders ||--o{ shipments : ships_with
  eyewear_frames ||--o{ inventory_items : stocked_as
  eyewear_lenses ||--o{ inventory_items : stocked_as
  connector_accounts ||--o{ integration_events : logs

  customers {
    uuid id
    text customer_number
    text first_name
    text last_name
    text email
    jsonb address
    boolean marketing_consent
    boolean medical_data_consent
  }

  eye_prescriptions {
    uuid id
    uuid customer_id
    date exam_date
    numeric od_sphere
    numeric od_cylinder
    integer od_axis
    numeric os_sphere
    numeric os_cylinder
    integer os_axis
    numeric pd_distance
  }

  eyewear_frames {
    uuid id
    text sku
    text brand
    text model
    text color
    text size
  }

  eyewear_lenses {
    uuid id
    text sku
    text lens_type
    text material
    text coating
    numeric index_value
  }

  inventory_items {
    uuid id
    text sku
    text product_type
    text name
    integer quantity_on_hand
    integer quantity_reserved
    integer reorder_level
  }

  connector_accounts {
    uuid id
    text provider
    text status
    text auth_type
    jsonb scopes
    text secret_ref
  }
```
