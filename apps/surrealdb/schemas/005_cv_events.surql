-- ============================================================================
-- 005_cv_events.surql — Table events
-- ============================================================================

-- ── page_view CREATE event ──────────────────────────────────────────────────
-- Placeholder for future analytics aggregation.
-- When a page_view is created, this event fires. Future iterations could
-- aggregate into hourly/daily rollup tables, trigger alerts, or push to
-- an external analytics pipeline.

DEFINE EVENT page_view_created ON TABLE page_view WHEN $event = "CREATE" THEN {
    -- TODO: aggregate into page_view_daily rollup table
    -- CREATE page_view_daily SET
    --     path = $after.path,
    --     date = time::floor($after.timestamp, 1d),
    --     count += 1;
    RETURN NONE;
};
