-- ============================================================================
-- Meerkat CRM initial schema rollback (MySQL)
-- Drops all tables created by 000001_initial_schema.up.sql, in reverse
-- dependency order (children first, parents last).
-- ============================================================================

DROP TABLE IF EXISTS carddav_contact_links;
DROP TABLE IF EXISTS carddav_connections;
DROP TABLE IF EXISTS calendar_event_links;
DROP TABLE IF EXISTS calendar_subscriptions;
DROP TABLE IF EXISTS webhook_deliveries;
DROP TABLE IF EXISTS webhooks;
DROP TABLE IF EXISTS api_tokens;
DROP TABLE IF EXISTS reminder_completions;
DROP TABLE IF EXISTS carddav_sync;
DROP TABLE IF EXISTS job_executions;
DROP TABLE IF EXISTS reminders;
DROP TABLE IF EXISTS relationships;
DROP TABLE IF EXISTS notes;
DROP TABLE IF EXISTS activity_contacts;
DROP TABLE IF EXISTS activities;
DROP TABLE IF EXISTS contacts;
DROP TABLE IF EXISTS users;
