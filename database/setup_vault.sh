#!/usr/bin/env bash

# Exit on any error
set -eo pipefail

# 1. Load variables from your .env
# We use a subshell to avoid polluting your current terminal environment
if [ -f .env ]; then
    # This specifically looks for lines starting with VAULT_
    export $(grep '^VAULT_' .env | xargs)
else
    echo "❌ Error: .env file not found in $(pwd)"
    exit 1
fi

echo "🚀 Starting Vault Migration on Legion (WSL)..."
echo "Target DB: $VAULT_DB_NAME"
echo "Target User: $VAULT_DB_USER"

# 2. Execute Administrative Tasks as the 'postgres' superuser
# We use sudo -u postgres because only that user can create new roles/DBs initially
sudo -u postgres psql <<EOF
-- Create the Database if it doesn't exist
SELECT 'CREATE DATABASE $VAULT_DB_NAME' 
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$VAULT_DB_NAME')\gexec

-- Create the User/Role if it doesn't exist
DO \$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$VAULT_DB_USER') THEN
        CREATE ROLE $VAULT_DB_USER WITH LOGIN PASSWORD '$VAULT_DB_PASS';
    END IF;
END
\$$;

-- Ensure the user has Superuser rights for this Dev environment
ALTER USER $VAULT_DB_USER WITH SUPERUSER;
GRANT ALL PRIVILEGES ON DATABASE $VAULT_DB_NAME TO $VAULT_DB_USER;
EOF

echo "✅ Database and User verified."

# 3. Apply the Project Sentinel Schema
# We pass the password via PGPASSWORD to avoid interactive prompts
echo "📝 Applying Schema from database/init_sentinel_db.sql..."
PGPASSWORD=$VAULT_DB_PASS psql -h localhost -U $VAULT_DB_USER -d $VAULT_DB_NAME -f database/init_sentinel_db.sql

echo "🌟 Vault is fully synchronized and ready for the Brain!"