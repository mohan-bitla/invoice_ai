# Agent Specifications

InvoiceAI: AI-Powered Vendor Invoice Processor for SMEs is a niche micro-SaaS that automates PDF invoice extraction, validation, and CRM updates, targeting Coimbatore-area ecommerce and manufacturing firms handling 50–500 invoices/month. It delivers 80% time savings on manual entry, priced at $29–$79/month per user, aligning with realistic revenue models.

InvoiceAI solves repetitive vendor invoice processing—extracting data from PDFs/emails, matching POs, flagging discrepancies, and auto-updating QuickBooks/Supabase—for SMEs lacking accounting staff. Core value: Reduce errors by 99% and processing from hours to minutes via AI. 

Target Market
Coimbatore SMEs in manufacturing/ecommerce (e.g., textile exporters, online retailers) with high invoice volume but manual workflows. User personas: Owner/operators (non-tech, 30–50yo) needing simple dashboard; bookkeepers for approvals. Market size: 10k+ local firms; acquire via LinkedIn/local chambers.

| Priority | Feature                        | Description                                                                                                    |
| -------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| Must     | Invoice Upload & AI Extraction | Drag-drop PDFs/emails; OpenAI/Claude extracts vendor, amount, date, line items (90% accuracy).billingplatform​ |
| Must     | PO Matching & Validation       | Auto-match to Supabase POs; flag mismatches >5% for approval.billingplatform​                                  |
| Must     | Auto-CRM Update                | Push to QuickBooks/Supabase/Google Sheets via Zapier webhook.billingplatform​                                  |
| Should   | Dashboard & Reports            | View processed invoices, error log, weekly summaries.zartis​                                                   |
| Should   | Multi-User Roles               | Owner approves; bookkeeper uploads (RBAC).zartis​                                                              |
| Could    | Tone/Compliance Check          | Flag GST anomalies for India compliance.                                                                       |
| Won't    | Full AP Workflow               | Predictive payments (post-MVP).                                                                                |

## Technical Specs
- Ruby Version: 3.4.3
- Rails Version: 8.0
- Database: mysql
- Frontend React + vite
- AI via OpenAI API
- Integrations Zapier/Make


## High-Level Architecture
Modular monolith: Frontend serves API/dashboard; backend orchestrates extraction/matching; MySQL for data/auth; external AI/queues for heavy lifts. Multi-tenant isolation via row-level security

[User Browser] --> React Frontend (Vercel) 
                  |
                  v
[API Gateway: Rails] <--> [MySQL (Data/Auth)]
                  |                  |
                  v                  v
[Worker Queue: SolidQueue] --> [AI Processor: OpenAI/Claude API]
                  |                       |
                  v                       v
[Integrations: Zapier Webhooks] <-- [CRM: QuickBooks/Sheets]


## Components Breakdown

| Component     | Tech                              | Responsibilities                                                                    | Scalability                                          |
| ------------- | --------------------------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------- |
| Frontend      | React/Next.js + Tailwind          | Dashboard, upload UI, real-time status (WebSockets).                                | Vercel auto-scales. reddit​                          |
| Backend API   | Ruby on Rails/NestJS + TypeORM    | Auth (JWT), endpoints (/upload, /review), business logic.                           | Horizontal pods on Render ($20/mo). reddit​          |
| Database      | Mysql (Postgres)               | Invoices, POs, users (RLS for tenants); indexes on vendor/date.                     | Managed scaling; your MySQL skills transfer. reddit​ |
| Queue         | SolidQueue       | Async jobs: process invoice → extract → match.                                      | Auto-scale workers. softellar​                       |
| AI Extraction | OpenAI Vision/Claude (PDF → JSON) | OCR/extract fields (vendor, total, items); 90% acc. Fallback human review. turian+1 |                                                      |
| Integrations  | Zapier/Make webhooks              | Push to QuickBooks/Sheets; PO fetch.                                                | No-code, $20/mo. turian​                             |
| Monitoring    | Superset + Sentry                 | Logs, errors, usage dashboards.                                                     | Your toolset. softellar​                             |


Data Flow
User uploads PDF → Frontend → API (store in Supabase Storage).

API enqueues job → Worker pulls → Calls OpenAI (prompt: "Extract invoice JSON: vendor, date, total, lines").

Validate/match vs POs (SQL query) → Flag anomalies → Notify user (email/WebSocket).

Approve → Webhook to CRM. Error handling: Retry 3x, quarantine bad PDFs.

Security & Compliance
Auth: Supabase Auth (OAuth/email); RBAC (owner/bookkeeper).

Data: Encrypt at rest (Supabase); PII masking; India GST compliance checks.

Rate limits: 10/min/user; API keys for OpenAI.

Multi-tenant: Schema per account or RLS policies.
​

Deployment & Ops
Infra: Vercel (FE), Render/Heroku (BE, $20–50/mo), Supabase Pro ($25/mo).

CI/CD: GitHub Actions; Docker for workers.

Cost: $100–200/mo at 100 users; monitor via Superset.

Backup: Supabase PITR; S3 for PDFs.
​

Performance & Scaling
Bottlenecks: AI calls (parallelize); DB queries (indexes on extract_date).

MVP: 100 concurrent users; scale to queues + read replicas.

Metrics: 99% uptime, <10s process time.

## Core Tables

| Table           | Purpose                         |
| --------------- | ------------------------------- |
| accounts        | Multi-tenant isolation (SMEs)   |
| users           | RBAC per account                |
| purchase_orders | Matching source                 |
| invoices        | Core entity with extracted data |
| invoice_lines   | Normalized items                |
| extractions     | AI raw output + status          |
| integrations    | CRM webhooks                    |

## ER Diagram (Text)

accounts (id) 1:N users (id, account_id)
         1:N purchase_orders (id, account_id)
                   1:N invoices (id, po_id?, account_id)
                            1:N invoice_lines (id, invoice_id)
                            1:N extractions (id, invoice_id)
accounts 1:N integrations (id, account_id)


## Schema SQL

```sql
-- Enable RLS policies later for multi-tenancy
CREATE EXTENSION vector; -- For future embeddings

-- 1. Accounts (Tenants/SMEs)
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    industry VARCHAR(100), -- 'ecommerce', 'manufacturing'
    max_invoices INTEGER DEFAULT 500,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 2. Users (RBAC)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES accounts(id),
    role VARCHAR(50) DEFAULT 'bookkeeper' CHECK (role IN ('owner', 'bookkeeper', 'viewer')),
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_users_account ON users(account_id);

-- 3. Purchase Orders (Matching source)
CREATE TABLE purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    po_number VARCHAR(100) UNIQUE,
    vendor_name VARCHAR(255),
    total_amount DECIMAL(12,2),
    expected_items JSONB, -- For flexible matching
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_po_account_vendor ON purchase_orders(account_id, vendor_name);

-- 4. Invoices (Core)
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    po_id UUID REFERENCES purchase_orders(id),
    file_url VARCHAR(500), -- Supabase Storage
    invoice_number VARCHAR(100),
    vendor_name VARCHAR(255),
    invoice_date DATE,
    due_date DATE,
    total_amount DECIMAL(12,2),
    currency VARCHAR(3) DEFAULT 'INR',
    status VARCHAR(50) DEFAULT 'uploaded' -- uploaded, extracting, extracted, matched, approved, exported, error
    extracted_data JSONB, -- Full AI output
    match_confidence DECIMAL(3,2), -- 0.0-1.0
    discrepancy_amount DECIMAL(12,2) DEFAULT 0,
    notes TEXT,
    processed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_invoices_account_status ON invoices(account_id, status);
CREATE INDEX idx_invoices_vendor_date ON invoices(account_id, vendor_name, invoice_date);

-- 5. Invoice Lines (Normalized items)
CREATE TABLE invoice_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    description TEXT,
    quantity DECIMAL(10,3),
    unit_price DECIMAL(12,2),
    line_total DECIMAL(12,2),
    sku VARCHAR(100)
);
CREATE INDEX idx_lines_invoice ON invoice_lines(invoice_id);

-- 6. Extractions (AI job tracking)
CREATE TABLE extractions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL UNIQUE REFERENCES invoices(id) ON DELETE CASCADE,
    ai_model VARCHAR(50), -- 'gpt-4-vision', 'claude-3'
    raw_prompt TEXT,
    raw_response JSONB,
    confidence DECIMAL(3,2),
    error_message TEXT,
    duration_ms INTEGER,
    cost_usd DECIMAL(8,6),
    status VARCHAR(50) DEFAULT 'pending', -- pending, completed, failed
    created_at TIMESTAMP DEFAULT NOW()
);

-- 7. Integrations (CRM webhooks)
CREATE TABLE integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    name VARCHAR(100), -- 'QuickBooks', 'Zoho'
    type VARCHAR(50),
    config JSONB, -- API keys, endpoints (encrypted)
    is_active BOOLEAN DEFAULT true,
    last_sync TIMESTAMP
);

```

Key Design Decisions

Multi-Tenancy: account_id on all tables + Supabase RLS policies (e.g., current_setting('app.current_account_id')).

JSONB Flexibility: extracted_data, expected_items for varying invoice formats without schema changes.
​

Audit Trail: All tables have created_at; add updated_at trigger if needed.

Indexes: Cover 95% queries (dashboard lists, vendor lookups, status filtering).

AI Tracking: extractions table monitors costs/accuracy for optimization.


## Product Specs
- Signup/Login → Dashboard.

- Upload invoice PDF → AI processes (10s) → Review extracted data → Approve/Match PO → Auto-export to CRM.

- Daily email digest of processed/pending.
​

Non-Functional Requirements
- Performance: <5s extraction; scale to 1k invoices/month.
​

- Security: Encrypt uploads (GDPR-compliant); OAuth for integrations.
​

- UI: Mobile-responsive, Tamil/English toggle for local users.

- Uptime: 99%; monitored via Superset (your tool).
​

Pricing & Monetization
Freemium: 50 free invoices/month; Pro $29/user (500 invoices); Enterprise $79 (unlimited + custom). Goal: 50 users = $1.5k–$4k MRR in 6 months.

Success Metrics
- Activation: 70% upload-to-process completion.

- Retention: 80% month 2.

- Revenue: $3k MRR by month 3 via 100 trials.

- Feedback: NPS >8; iterate via user interviews.
