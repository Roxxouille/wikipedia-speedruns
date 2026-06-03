# Docker Compose deployment

1. Copy the example env file and edit every secret:

   ```sh
   cp .env.example .env
   nano .env
   ```

2. Build and start the stack:

   ```sh
   docker compose up -d --build
   ```

   The `web` container writes `config/prod.json` from environment variables, waits for MySQL, and initializes the schema with `scripts/create_db.py` on startup.

3. Create an admin account if needed:

   ```sh
   docker compose exec web python scripts/create_admin_account.py
   ```

4. View logs:

   ```sh
   docker compose logs -f web
   docker compose logs -f celery
   ```

## Services

- `web`: Flask app served by Gunicorn on container port `8000`; exposed as `${WEB_PORT:-80}` on the host.
- `db`: MySQL 8 with persistent `mysql-data` volume.
- `redis`: Redis for Celery broker/results.
- `celery`: worker for scraper async endpoints.

## Optional data

The compose file mounts `./data` read-only into `/data` in app containers. If you have a PageRank file, put it in `./data` and set for example:

```env
PAGERANK_FILE=/data/pagerank.txt
```

The scraper path endpoint also expects the separate `scraper_graph` MySQL database described in the README; this compose file only initializes the main app schema.
