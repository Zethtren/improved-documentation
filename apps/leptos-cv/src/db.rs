#[cfg(feature = "ssr")]
pub async fn query_surreal(sql: &str) -> Result<serde_json::Value, String> {
    let client = reqwest::Client::new();
    let url =
        std::env::var("SURREALDB_URL").unwrap_or_else(|_| "http://localhost:8000".to_string());

    let resp = client
        .post(format!("{}/sql", url))
        .header("Accept", "application/json")
        .header("surreal-ns", "houston")
        .header("surreal-db", "cv")
        .basic_auth(
            "root",
            Some(std::env::var("SURREAL_PASS").unwrap_or_else(|_| "root".to_string())),
        )
        .body(sql.to_string())
        .send()
        .await
        .map_err(|e| e.to_string())?;

    let data: serde_json::Value = resp.json().await.map_err(|e| e.to_string())?;

    // SurrealDB returns an array of results; get the first result's "result" field
    data.get(0)
        .and_then(|r| r.get("result"))
        .cloned()
        .ok_or_else(|| "No result from SurrealDB".to_string())
}
