FROM surrealdb/surrealdb:v2

# Copy schema and seed files
COPY schemas/ /opt/surrealdb/schemas/
COPY seed/ /opt/surrealdb/seed/
COPY --chmod=755 scripts/ /opt/surrealdb/scripts/

# Default command starts SurrealDB with auth enabled
ENTRYPOINT ["surreal"]
CMD ["start", "-u", "root", "-p", "root", "-b", "0.0.0.0:8000", "memory"]
