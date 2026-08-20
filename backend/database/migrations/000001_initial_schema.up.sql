-- ============================================================================
-- Meerkat CRM initial schema (MySQL)
-- This is a consolidated, native-MySQL rebuild of the original 23 SQLite
-- migrations. It creates the final schema state in a single migration.
-- Old SQLite migrations are preserved in database/migrations_sqlite_legacy/.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at                  DATETIME(3) NULL,
    updated_at                  DATETIME(3) NULL,
    deleted_at                  DATETIME(3) NULL,
    username                    VARCHAR(191) NOT NULL,
    password                    VARCHAR(255) NOT NULL,
    email                       VARCHAR(191) NOT NULL,
    password_reset_token_hash   VARCHAR(255) NULL,
    password_reset_expires_at   DATETIME(3) NULL,
    password_reset_requested_at DATETIME(3) NULL,
    language                    VARCHAR(10) NOT NULL DEFAULT 'en',
    custom_field_names          TEXT NULL,
    is_admin                    TINYINT(1) NOT NULL DEFAULT 0,
    date_format                 VARCHAR(10) NOT NULL DEFAULT 'eu',
    oidc_subject                VARCHAR(255) NULL,
    oidc_provider               VARCHAR(100) NULL,
    enabled_contact_fields      TEXT NULL,
    UNIQUE KEY uq_users_username (username),
    UNIQUE KEY uq_users_email (email),
    UNIQUE KEY uq_users_oidc_subject (oidc_subject, oidc_provider),
    KEY idx_users_deleted_at (deleted_at),
    KEY idx_users_password_reset_token_hash (password_reset_token_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- contacts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS contacts (
    id                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at        DATETIME(3) NULL,
    updated_at        DATETIME(3) NULL,
    deleted_at        DATETIME(3) NULL,
    firstname         VARCHAR(255) NOT NULL,
    lastname          VARCHAR(255) NULL,
    nickname          VARCHAR(255) NULL,
    gender            VARCHAR(50) NULL,
    email             VARCHAR(191) NULL,
    phone             VARCHAR(100) NULL,
    birthday          VARCHAR(10) NULL,
    photo             TEXT NULL,
    photo_thumbnail   TEXT NULL,
    address           TEXT NULL,
    how_we_met        TEXT NULL,
    food_preference   TEXT NULL,
    work_information  TEXT NULL,
    contact_information TEXT NULL,
    circles           TEXT NULL,
    user_id           BIGINT UNSIGNED NULL,
    vcard_uid         VARCHAR(64) NULL,
    vcard_extra       TEXT NULL,
    etag              VARCHAR(255) NULL,
    custom_fields     TEXT NULL,
    archived          TINYINT(1) NOT NULL DEFAULT 0,
    emails            TEXT NULL,
    phones            TEXT NULL,
    addresses         TEXT NULL,
    urls              TEXT NULL,
    impps             TEXT NULL,
    prefix            VARCHAR(100) NOT NULL DEFAULT '',
    middle_name       VARCHAR(100) NOT NULL DEFAULT '',
    suffix            VARCHAR(100) NOT NULL DEFAULT '',
    organization      VARCHAR(255) NOT NULL DEFAULT '',
    department        VARCHAR(255) NOT NULL DEFAULT '',
    job_title         VARCHAR(255) NOT NULL DEFAULT '',
    role              VARCHAR(255) NOT NULL DEFAULT '',
    anniversary       VARCHAR(20) NOT NULL DEFAULT '',
    KEY idx_contacts_deleted_at (deleted_at),
    KEY idx_contacts_firstname (firstname),
    KEY idx_contacts_lastname (lastname),
    KEY idx_contacts_email (email),
    KEY idx_contacts_user_id (user_id),
    UNIQUE KEY uq_contacts_vcard_uid_user (user_id, vcard_uid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- activities
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS activities (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at  DATETIME(3) NULL,
    updated_at  DATETIME(3) NULL,
    deleted_at  DATETIME(3) NULL,
    title       VARCHAR(255) NOT NULL,
    description TEXT NULL,
    location    VARCHAR(255) NULL,
    date        DATETIME(3) NOT NULL,
    user_id     BIGINT UNSIGNED NULL,
    KEY idx_activities_deleted_at (deleted_at),
    KEY idx_activities_date (date),
    KEY idx_activities_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- activity_contacts (join table)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS activity_contacts (
    activity_id BIGINT UNSIGNED NOT NULL,
    contact_id  BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (activity_id, contact_id),
    KEY idx_activity_contacts_activity_id (activity_id),
    KEY idx_activity_contacts_contact_id (contact_id),
    CONSTRAINT fk_activity_contacts_activity FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE,
    CONSTRAINT fk_activity_contacts_contact  FOREIGN KEY (contact_id)  REFERENCES contacts(id)    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- notes
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notes (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at  DATETIME(3) NULL,
    updated_at  DATETIME(3) NULL,
    deleted_at  DATETIME(3) NULL,
    content     TEXT NOT NULL,
    date        DATETIME(3) NOT NULL,
    contact_id  BIGINT UNSIGNED NULL,
    user_id     BIGINT UNSIGNED NULL,
    KEY idx_notes_deleted_at (deleted_at),
    KEY idx_notes_contact_id (contact_id),
    KEY idx_notes_date (date),
    KEY idx_notes_user_id (user_id),
    CONSTRAINT fk_notes_contact FOREIGN KEY (contact_id) REFERENCES contacts(id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- relationships
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS relationships (
    id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at         DATETIME(3) NULL,
    updated_at         DATETIME(3) NULL,
    deleted_at         DATETIME(3) NULL,
    name               VARCHAR(255) NOT NULL,
    type               VARCHAR(50) NOT NULL,
    gender             VARCHAR(50) NULL,
    birthday           VARCHAR(10) NULL,
    contact_id         BIGINT UNSIGNED NOT NULL,
    related_contact_id BIGINT UNSIGNED NULL,
    user_id            BIGINT UNSIGNED NULL,
    KEY idx_relationships_deleted_at (deleted_at),
    KEY idx_relationships_contact_id (contact_id),
    KEY idx_relationships_related_contact_id (related_contact_id),
    KEY idx_relationships_user_id (user_id),
    CONSTRAINT fk_relationships_contact FOREIGN KEY (contact_id) REFERENCES contacts(id),
    CONSTRAINT fk_relationships_related_contact FOREIGN KEY (related_contact_id) REFERENCES contacts(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- reminders
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reminders (
    id                     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at             DATETIME(3) NULL,
    updated_at             DATETIME(3) NULL,
    deleted_at             DATETIME(3) NULL,
    message                TEXT NOT NULL,
    by_mail                TINYINT(1) NOT NULL DEFAULT 0,
    remind_at              DATETIME(3) NOT NULL,
    recurrence             VARCHAR(255) NOT NULL,
    reoccur_from_completion TINYINT(1) NOT NULL DEFAULT 1,
    last_sent              DATETIME(3) NULL,
    contact_id             BIGINT UNSIGNED NOT NULL,
    user_id                BIGINT UNSIGNED NULL,
    completed              TINYINT(1) NOT NULL DEFAULT 0,
    email_sent             TINYINT(1) NOT NULL DEFAULT 0,
    KEY idx_reminders_deleted_at (deleted_at),
    KEY idx_reminders_contact_id (contact_id),
    KEY idx_reminders_remind_at (remind_at),
    KEY idx_reminders_user_id (user_id),
    CONSTRAINT fk_reminders_contact FOREIGN KEY (contact_id) REFERENCES contacts(id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- job_executions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS job_executions (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    job_name    VARCHAR(255) NOT NULL,
    last_run_at DATETIME(3) NOT NULL,
    locked_at   DATETIME(3) NULL,
    locked_by   VARCHAR(255) NULL,
    created_at  DATETIME(3) NULL,
    updated_at  DATETIME(3) NULL,
    deleted_at  DATETIME(3) NULL,
    UNIQUE KEY uq_job_executions_job_name (job_name),
    KEY idx_job_executions_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- carddav_sync
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS carddav_sync (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id       BIGINT UNSIGNED NOT NULL,
    sync_token    TEXT NOT NULL,
    last_modified DATETIME(3) NOT NULL,
    UNIQUE KEY uq_carddav_sync_user (user_id),
    CONSTRAINT fk_carddav_sync_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- reminder_completions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reminder_completions (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    deleted_at   DATETIME(3) NULL,
    user_id      BIGINT UNSIGNED NOT NULL,
    reminder_id  BIGINT UNSIGNED NULL,
    contact_id   BIGINT UNSIGNED NOT NULL,
    message      TEXT NOT NULL,
    completed_at DATETIME(3) NOT NULL,
    KEY idx_reminder_completions_contact_id (contact_id),
    KEY idx_reminder_completions_user_id (user_id),
    CONSTRAINT fk_reminder_completions_user    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
    CONSTRAINT fk_reminder_completions_contact FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- api_tokens
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS api_tokens (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    deleted_at   DATETIME(3) NULL,
    user_id      BIGINT UNSIGNED NOT NULL,
    name         VARCHAR(255) NOT NULL,
    token_hash   VARCHAR(255) NOT NULL,
    last_used_at DATETIME(3) NULL,
    revoked_at   DATETIME(3) NULL,
    UNIQUE KEY uq_api_tokens_token_hash (token_hash),
    KEY idx_api_tokens_user_id (user_id),
    CONSTRAINT fk_api_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- webhooks
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS webhooks (
    id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at DATETIME(3) NULL,
    updated_at DATETIME(3) NULL,
    deleted_at DATETIME(3) NULL,
    user_id    BIGINT UNSIGNED NOT NULL,
    name       VARCHAR(255) NOT NULL,
    url        VARCHAR(2048) NOT NULL,
    events     TEXT NOT NULL,
    secret     VARCHAR(255) NOT NULL,
    is_active  TINYINT(1) NOT NULL DEFAULT 1,
    KEY idx_webhooks_user_id (user_id),
    KEY idx_webhooks_deleted_at (deleted_at),
    CONSTRAINT fk_webhooks_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- webhook_deliveries
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS webhook_deliveries (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at    DATETIME(3) NULL,
    updated_at    DATETIME(3) NULL,
    deleted_at    DATETIME(3) NULL,
    webhook_id    BIGINT UNSIGNED NOT NULL,
    event_type    VARCHAR(255) NOT NULL,
    payload       MEDIUMTEXT NOT NULL,
    status_code   INT NULL,
    error         TEXT NULL,
    attempts      INT NOT NULL DEFAULT 1,
    next_retry_at DATETIME(3) NULL,
    KEY idx_webhook_deliveries_webhook_id (webhook_id),
    KEY idx_webhook_deliveries_next_retry_at (next_retry_at),
    CONSTRAINT fk_webhook_deliveries_webhook FOREIGN KEY (webhook_id) REFERENCES webhooks(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- calendar_subscriptions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS calendar_subscriptions (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at          DATETIME(3) NULL,
    updated_at          DATETIME(3) NULL,
    deleted_at          DATETIME(3) NULL,
    user_id             BIGINT UNSIGNED NOT NULL,
    name                VARCHAR(255) NOT NULL,
    url                 VARCHAR(2048) NOT NULL,
    username            VARCHAR(255) NOT NULL DEFAULT '',
    password_encrypted  TEXT NOT NULL,
    sync_enabled        TINYINT(1) NOT NULL DEFAULT 1,
    past_days           INT NOT NULL DEFAULT 5,
    future_days         INT NOT NULL DEFAULT 10,
    last_synced_at      DATETIME(3) NULL,
    last_sync_status    VARCHAR(255) NOT NULL DEFAULT '',
    last_sync_error     TEXT NULL,
    KEY idx_calendar_subscriptions_user_id (user_id),
    KEY idx_calendar_subscriptions_deleted_at (deleted_at),
    CONSTRAINT fk_calendar_subscriptions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- calendar_event_links
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS calendar_event_links (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at      DATETIME(3) NULL,
    updated_at      DATETIME(3) NULL,
    subscription_id BIGINT UNSIGNED NOT NULL,
    user_id         BIGINT UNSIGNED NOT NULL,
    uid             VARCHAR(255) NOT NULL,
    activity_id     BIGINT UNSIGNED NOT NULL,
    content_hash    VARCHAR(64) NOT NULL,
    UNIQUE KEY uq_calendar_event_links_sub_uid (subscription_id, uid),
    KEY idx_calendar_event_links_user_id (user_id),
    KEY idx_calendar_event_links_activity_id (activity_id),
    CONSTRAINT fk_calendar_event_links_subscription FOREIGN KEY (subscription_id) REFERENCES calendar_subscriptions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- carddav_connections
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS carddav_connections (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at          DATETIME(3) NULL,
    updated_at          DATETIME(3) NULL,
    user_id             BIGINT UNSIGNED NOT NULL,
    base_url            VARCHAR(2048) NOT NULL,
    address_book_path   VARCHAR(2048) NOT NULL,
    address_book_name   VARCHAR(255) NOT NULL DEFAULT '',
    username            VARCHAR(255) NOT NULL DEFAULT '',
    password_encrypted  TEXT NOT NULL,
    direction           VARCHAR(20) NOT NULL DEFAULT 'two_way',
    sync_enabled        TINYINT(1) NOT NULL DEFAULT 1,
    sync_token          TEXT NOT NULL,
    last_synced_at      DATETIME(3) NULL,
    last_sync_status    VARCHAR(255) NOT NULL DEFAULT '',
    last_sync_error     TEXT NULL,
    last_sync_stats     TEXT NULL,
    UNIQUE KEY uq_carddav_connections_user_id (user_id),
    CONSTRAINT fk_carddav_connections_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- carddav_contact_links
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS carddav_contact_links (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_at    DATETIME(3) NULL,
    updated_at    DATETIME(3) NULL,
    connection_id BIGINT UNSIGNED NOT NULL,
    user_id       BIGINT UNSIGNED NOT NULL,
    contact_id    BIGINT UNSIGNED NOT NULL,
    remote_uid    VARCHAR(255) NOT NULL,
    remote_path   VARCHAR(2048) NOT NULL,
    remote_etag   VARCHAR(255) NOT NULL DEFAULT '',
    local_hash    VARCHAR(64) NOT NULL DEFAULT '',
    synced_at     DATETIME(3) NULL,
    UNIQUE KEY uq_carddav_links_conn_contact (connection_id, contact_id),
    UNIQUE KEY uq_carddav_links_conn_uid (connection_id, remote_uid),
    KEY idx_carddav_links_user_id (user_id),
    KEY idx_carddav_links_contact_id (contact_id),
    CONSTRAINT fk_carddav_links_connection FOREIGN KEY (connection_id) REFERENCES carddav_connections(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
