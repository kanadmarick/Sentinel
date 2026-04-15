import psycopg2
import redis
import os
from dotenv import load_dotenv

load_dotenv()

try:
    # Test Vault (Postgres)
    conn = psycopg2.connect(
        dbname=os.getenv("VAULT_DB_NAME"),
        user=os.getenv("VAULT_DB_USER"),
        password=os.getenv("VAULT_DB_PASS"),
        host="localhost"
    )
    print("✅ Vault Connection: SUCCESS")
    
    # Test Broker (Redis)
    r = redis.Redis(host='localhost', port=6379, db=0)
    print(f"✅ Broker Connection: {r.ping()}")

except Exception as e:
    print(f"❌ Connection Failed: {e}")