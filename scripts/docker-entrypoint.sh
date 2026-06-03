#!/bin/sh
set -eu

python - <<'PY'
import json
import os
import secrets
from pathlib import Path

config = {
    "SECRET_KEY": os.environ.get("SECRET_KEY") or secrets.token_urlsafe(32),
    "MYSQL_HOST": os.environ.get("MYSQL_HOST", "db"),
    "MYSQL_USER": os.environ.get("MYSQL_USER", "wikispeedruns"),
    "MYSQL_PASSWORD": os.environ.get("MYSQL_PASSWORD"),
    "DATABASE": os.environ.get("DATABASE", "wikipedia_speedruns"),
    "MAIL_USE_TLS": os.environ.get("MAIL_USE_TLS", "true").lower() in ("1", "true", "yes", "on"),
}

optional_string_keys = [
    "GOOGLE_OAUTH_CLIENT_ID",
    "GOOGLE_OAUTH_CLIENT_SECRET",
    "MAIL_SERVER",
    "MAIL_USERNAME",
    "MAIL_PASSWORD",
    "MAIL_DEFAULT_SENDER",
    "CELERY_BROKER_URL",
    "CELERY_RESULT_BACKEND",
    "PAGERANK_FILE",
]
for key in optional_string_keys:
    value = os.environ.get(key)
    if value:
        config[key] = value

if os.environ.get("MAIL_PORT"):
    config["MAIL_PORT"] = int(os.environ["MAIL_PORT"])

if os.environ.get("SENTRY_ENABLED"):
    config["SENTRY_ENABLED"] = os.environ["SENTRY_ENABLED"].lower() in ("1", "true", "yes", "on")

Path("config").mkdir(exist_ok=True)
Path("config/prod.json").write_text(json.dumps(config, indent=4))
PY

if [ "${WAIT_FOR_DB:-1}" = "1" ]; then
  python - <<'PY'
import os
import sys
import time
import pymysql

host = os.environ.get("MYSQL_HOST", "db")
user = os.environ.get("MYSQL_USER", "wikispeedruns")
password = os.environ.get("MYSQL_PASSWORD")

for attempt in range(60):
    try:
        conn = pymysql.connect(host=host, user=user, password=password, connect_timeout=5)
        conn.close()
        sys.exit(0)
    except Exception as exc:
        if attempt == 59:
            print(f"Database did not become available: {exc}", file=sys.stderr)
            raise
        time.sleep(2)
PY
fi

if [ "${INIT_DB:-1}" = "1" ]; then
  (cd scripts && python create_db.py)
fi

exec "$@"
