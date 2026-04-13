-- Project Sentinel: AI Orchestrator Unified Schema (V3 - Data Ingress Focus)
-- Target: PostgreSQL (Mac M1 Vault)

-- Enable pgcrypto so the schema can generate UUID values for event records.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. INFRASTRUCTURE LAYER (Hardware & Identity)
-- Stores the machine inventory that the rest of the platform links back to.
CREATE TABLE IF NOT EXISTS servers (
    server_id VARCHAR(50) PRIMARY KEY,
    hostname VARCHAR(100),
    ip_address VARCHAR(45),
    os_family VARCHAR(20) DEFAULT 'Linux',
    total_ram_gb FLOAT,
    cpu_cores INT,
    env_tier VARCHAR(20) DEFAULT 'DEV', -- PROD, UAT, DEV
    location VARCHAR(50) DEFAULT 'Kolkata-DC', -- Geographical Location
    status VARCHAR(20) DEFAULT 'ACTIVE',
    simulation_group VARCHAR(50) DEFAULT 'REAL'
);

-- 2. SERVICE & JOB REGISTRY (The Knowledge Base)
-- Catalogs every tracked service, batch job, or pipeline endpoint running on a server.
CREATE TABLE IF NOT EXISTS service_inventory (
    id SERIAL PRIMARY KEY,
    server_id VARCHAR(50) REFERENCES servers(server_id),
    service_name VARCHAR(100) UNIQUE,
    service_type VARCHAR(50),          -- 'systemd', 'docker', 'autosys', 'etl'
    incoming_data_path TEXT,           -- The landing zone for files (e.g., /data/inbound/)
    log_path TEXT,                     -- Path for error analysis
    port INT,                          -- For REST/API services
    description TEXT,
    criticality INT DEFAULT 3,
    restart_command TEXT,
    metadata JSONB DEFAULT '{}'        -- Catch-all for unique service flags
);

-- 3. DATA LINEAGE & SLA LAYER (Observability)
-- Defines expected inbound datasets and the SLA targets used for monitoring them.
CREATE TABLE IF NOT EXISTS data_flows (
    flow_id VARCHAR(50) PRIMARY KEY,
    upstream_source VARCHAR(100),
    target_server VARCHAR(50) REFERENCES servers(server_id),
    expected_file_pattern VARCHAR(100), -- e.g., 'EOD_PRICES_*.csv'
    expected_by_time TIME,
    sla_buffer_minutes INT DEFAULT 15,
    last_success_ts TIMESTAMP,          -- Vital for AI to know 'When did it last work?'
    criticality INT DEFAULT 5
);

-- 4. UNIVERSAL EVENT STREAM (Unified Ingestion)
-- Captures operational events in a single stream for alerting, analysis, and AI workflows.
CREATE TABLE IF NOT EXISTS universal_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    server_id VARCHAR(50) REFERENCES servers(server_id),
    service_name VARCHAR(100),
    event_type VARCHAR(50),             -- 'FILE_ARRIVAL', 'SNS_TRIGGER', 'JOB_FAILURE', 'METRIC_PULSE'
    severity VARCHAR(20) DEFAULT 'INFO',
    event_payload JSONB,                -- e.g., {"filename": "EOD.csv", "size": "2GB"}
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. HUMAN-IN-THE-LOOP (HITL) & AI TRAINING LOG
-- Stores operator actions taken on incidents so successful fixes can later train automations.
CREATE TABLE IF NOT EXISTS hitl_resolutions (
    id SERIAL PRIMARY KEY,
    event_id UUID REFERENCES universal_events(event_id),
    operator_name VARCHAR(100),
    issue_summary TEXT,
    human_steps_taken JSONB,            -- Structured log of bash commands run
    resolution_notes TEXT,
    ai_ingested BOOLEAN DEFAULT FALSE
);

-- PERFORMANCE INDEXING
-- Add indexes on the most likely lookup fields for ingestion and monitoring queries.
CREATE INDEX IF NOT EXISTS idx_data_path ON service_inventory(incoming_data_path);
CREATE INDEX IF NOT EXISTS idx_flow_time ON data_flows(expected_by_time);
CREATE INDEX IF NOT EXISTS idx_event_server_type ON universal_events(server_id, event_type);

-- SEED DATA: Onboarding your Legion
-- Insert the local development machine once so the schema has an initial server to reference.
INSERT INTO servers (server_id, hostname, ip_address, total_ram_gb, cpu_cores, env_tier, simulation_group) 
VALUES ('legion-01', 'Kanads-Legion', '127.0.0.1', 32.0, 8, 'DEV', 'REAL')
ON CONFLICT (server_id) DO NOTHING;