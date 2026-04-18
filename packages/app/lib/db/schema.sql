CREATE TABLE IF NOT EXISTS users (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    wallet_address  TEXT    NOT NULL UNIQUE,
    username        TEXT    NOT NULL,
    token_id        INTEGER,
    created_at      INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS communities (
    id          INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL,
    location    TEXT    NOT NULL,
    host_wallet TEXT    NOT NULL,
    created_at  INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS community_members (
    community_id    INTEGER NOT NULL REFERENCES communities(id),
    wallet_address  TEXT    NOT NULL,
    joined_at       INTEGER NOT NULL DEFAULT (unixepoch()),
    PRIMARY KEY (community_id, wallet_address)
);

CREATE TABLE IF NOT EXISTS meetups (
    id                      INTEGER PRIMARY KEY,
    community_id            INTEGER NOT NULL REFERENCES communities(id),
    name                    TEXT    NOT NULL,
    start_time              INTEGER NOT NULL,
    end_time                INTEGER NOT NULL,
    master_nonce            TEXT    NOT NULL,
    qr_hash                 TEXT    NOT NULL,
    reputation_reward       INTEGER NOT NULL DEFAULT 0,
    min_reputation_required INTEGER NOT NULL DEFAULT 0,
    host_wallet             TEXT    NOT NULL,
    finalized               INTEGER NOT NULL DEFAULT 0,
    finalize_tx_hash        TEXT,
    created_at              INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE TABLE IF NOT EXISTS check_ins (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    meetup_id       INTEGER NOT NULL REFERENCES meetups(id),
    scanner_wallet  TEXT    NOT NULL,
    scan_type       TEXT    NOT NULL CHECK (scan_type IN ('meetup', 'member')),
    scannee_wallet  TEXT,
    scanned_at      INTEGER NOT NULL DEFAULT (unixepoch()),
    UNIQUE (meetup_id, scanner_wallet, scan_type, scannee_wallet)
);

CREATE INDEX IF NOT EXISTS idx_checkins_meetup_scanner
    ON check_ins (meetup_id, scanner_wallet);
