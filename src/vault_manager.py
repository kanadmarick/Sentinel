import os
import psycopg2
from psycopg2 import pool
from dotenv import load_dotenv

# Load the .env file from the current directory
load_dotenv()

class VaultManager:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(VaultManager, cls).__new__(cls)
            try:
                # Pulling from .env instead of hardcoding
                cls._instance.connection_pool = psycopg2.pool.ThreadedConnectionPool(
                    minconn=os.getenv("VAULT_POOL_MIN", 5),
                    maxconn=os.getenv("VAULT_POOL_MAX", 20),
                    user=os.getenv("VAULT_DB_USER"),
                    password=os.getenv("VAULT_DB_PASS"),
                    host=os.getenv("VAULT_DB_HOST"),
                    port=os.getenv("VAULT_DB_PORT"),
                    database=os.getenv("VAULT_DB_NAME")
                )
                print(f"🚀 Vault Pool Initialized: Connected to {os.getenv('VAULT_DB_HOST')}")
            except Exception as e:
                print(f"❌ .env Config Error: {e}")
        return cls._instance

    def get_connection(self):
        return self.connection_pool.getconn()

    def release_connection(self, conn):
        self.connection_pool.putconn(conn)