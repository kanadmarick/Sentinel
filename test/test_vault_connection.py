import psycopg2
import sys
import os
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

VAULT_IP =os.environ.get("VAULT_IP")
DB_NAME = os.environ.get("VAULT_DB_NAME", "sentinel_db")  # Get the database name from an environment variable, with a default fallback
DB_USER = os.environ.get("VAULT_DB_USER", "sentinel_admin")  # Get the database user from an environment variable, with a default fallback
DB_PASSWORD = os.environ.get("VAULT_DB_PASS", "default_password")  # Get the database password from an environment variable, with a default fallback


def test_remote_connection():
    print(f"Attempting to connect to PostgreSQL database at {VAULT_IP} with user '{DB_USER}'... ")
    try:
        connection = psycopg2.connect(
            user=DB_USER,
            password=DB_PASSWORD,
            host=VAULT_IP,
            port="5432",
            database=DB_NAME
        )
        print(f"Successfully connected to PostgreSQL database '{DB_NAME}' at {VAULT_IP} as user '{DB_USER}'.")
    except (Exception, psycopg2.Error) as error:
        print("Error while connecting to PostgreSQL", error)
        
        
if __name__ == "__main__":
    test_remote_connection()
