FROM surrealdb/surrealdb:v2 AS server

# Copy schema and seed files
COPY schemas/ /opt/surrealdb/schemas/
COPY seed/ /opt/surrealdb/seed/
COPY --chmod=755 scripts/ /opt/surrealdb/scripts/

# Default command starts SurrealDB with auth enabled
ENTRYPOINT ["/surreal"]
CMD ["start", "-u", "root", "-p", "root", "-b", "0.0.0.0:8000", "memory"]

# Init image: needs bash + curl + surreal binary (debian for glibc compat)
FROM debian:bookworm-slim AS init

RUN apt-get update && apt-get install -y --no-install-recommends bash curl && rm -rf /var/lib/apt/lists/*
COPY --from=server /surreal /usr/local/bin/surreal
COPY schemas/ /opt/surrealdb/schemas/
COPY seed/ /opt/surrealdb/seed/
COPY --chmod=755 scripts/ /opt/surrealdb/scripts/

ENTRYPOINT ["/opt/surrealdb/scripts/init.sh"]
