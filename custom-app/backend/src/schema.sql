CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_number TEXT UNIQUE DEFAULT ('C-' || upper(substr(gen_random_uuid()::text, 1, 8))),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    date_of_birth DATE,
    address JSONB NOT NULL DEFAULT '{}'::jsonb,
    marketing_consent BOOLEAN NOT NULL DEFAULT false,
    medical_data_consent BOOLEAN NOT NULL DEFAULT false,
    notes TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS eye_prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    exam_date DATE NOT NULL DEFAULT CURRENT_DATE,
    prescriber TEXT,
    od_sphere NUMERIC(5,2),
    od_cylinder NUMERIC(5,2),
    od_axis INTEGER CHECK (od_axis IS NULL OR od_axis BETWEEN 0 AND 180),
    od_add NUMERIC(5,2),
    od_prism TEXT,
    os_sphere NUMERIC(5,2),
    os_cylinder NUMERIC(5,2),
    os_axis INTEGER CHECK (os_axis IS NULL OR os_axis BETWEEN 0 AND 180),
    os_add NUMERIC(5,2),
    os_prism TEXT,
    pd_distance NUMERIC(5,2),
    pd_near NUMERIC(5,2),
    notes TEXT,
    attachment_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS eyewear_frames (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    color TEXT,
    size TEXT,
    material TEXT,
    supplier TEXT,
    barcode TEXT,
    retail_price_cents INTEGER NOT NULL DEFAULT 0,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS eyewear_lenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE NOT NULL,
    lens_type TEXT NOT NULL,
    material TEXT,
    index_value NUMERIC(4,2),
    coating TEXT,
    supplier TEXT,
    barcode TEXT,
    retail_price_cents INTEGER NOT NULL DEFAULT 0,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT UNIQUE NOT NULL,
    product_type TEXT NOT NULL CHECK (product_type IN ('frame', 'lens', 'accessory')),
    frame_id UUID REFERENCES eyewear_frames(id) ON DELETE SET NULL,
    lens_id UUID REFERENCES eyewear_lenses(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    quantity_on_hand INTEGER NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    quantity_reserved INTEGER NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
    reorder_level INTEGER NOT NULL DEFAULT 0 CHECK (reorder_level >= 0),
    location TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT UNIQUE DEFAULT ('O-' || upper(substr(gen_random_uuid()::text, 1, 8))),
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    source_provider TEXT,
    external_order_id TEXT,
    status TEXT NOT NULL DEFAULT 'draft',
    total_cents INTEGER NOT NULL DEFAULT 0,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shipments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    tracking_number TEXT,
    label_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS connector_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'needs_credentials',
    auth_type TEXT NOT NULL,
    tenant_id TEXT,
    account_label TEXT,
    scopes JSONB NOT NULL DEFAULT '[]'::jsonb,
    secret_ref TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customer_external_refs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    external_id TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider, external_id)
);

CREATE TABLE IF NOT EXISTS integration_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT NOT NULL,
    event_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'received',
    external_id TEXT,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customers_name_trgm ON customers USING GIN ((first_name || ' ' || last_name) gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_prescriptions_customer ON eye_prescriptions(customer_id, exam_date DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_type ON inventory_items(product_type);
CREATE INDEX IF NOT EXISTS idx_inventory_reorder ON inventory_items(quantity_on_hand, reorder_level);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_shipments_provider_tracking ON shipments(provider, tracking_number);
CREATE INDEX IF NOT EXISTS idx_connector_accounts_provider ON connector_accounts(provider);
CREATE INDEX IF NOT EXISTS idx_integration_events_provider_created ON integration_events(provider, created_at DESC);
