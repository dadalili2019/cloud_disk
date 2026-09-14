PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

CREATE TABLE IF NOT EXISTS workspace (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','archived')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT
);

CREATE TABLE IF NOT EXISTS task (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo','doing','done','archived')),
    progress INTEGER NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
    next_step TEXT,
    priority TEXT CHECK (priority IN ('low','medium','high')),
    is_current INTEGER NOT NULL DEFAULT 0 CHECK (is_current IN (0,1)),
    sort_order REAL NOT NULL DEFAULT 0,
    due_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    completed_at TEXT,
    archived_at TEXT,
    FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_task_current_per_workspace
ON task(workspace_id) WHERE is_current = 1;

CREATE TABLE IF NOT EXISTS note (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    title TEXT NOT NULL,
    file_path TEXT NOT NULL UNIQUE,
    is_pinned INTEGER NOT NULL DEFAULT 0 CHECK (is_pinned IN (0,1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS issue (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','investigating','resolved','archived')),
    severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low','medium','high','blocker')),
    impact TEXT,
    hypothesis TEXT,
    next_investigation_step TEXT,
    resolution TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    resolved_at TEXT,
    archived_at TEXT,
    FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS resource (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    name TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    uri TEXT,
    description TEXT,
    is_pinned INTEGER NOT NULL DEFAULT 0 CHECK (is_pinned IN (0,1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS decision (
    id TEXT PRIMARY KEY,
    workspace_id TEXT NOT NULL,
    title TEXT NOT NULL,
    decision_text TEXT NOT NULL,
    rationale TEXT,
    revisit_condition TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','superseded','archived')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS knowledge (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    category TEXT,
    summary TEXT,
    use_when TEXT,
    file_path TEXT NOT NULL UNIQUE,
    is_pinned INTEGER NOT NULL DEFAULT 0 CHECK (is_pinned IN (0,1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT
);

CREATE TABLE IF NOT EXISTS entity_link (
    id TEXT PRIMARY KEY,
    from_type TEXT NOT NULL,
    from_id TEXT NOT NULL,
    to_type TEXT NOT NULL,
    to_id TEXT NOT NULL,
    relation_type TEXT NOT NULL,
    created_at TEXT NOT NULL,
    UNIQUE(from_type, from_id, to_type, to_id, relation_type)
);

CREATE INDEX IF NOT EXISTS idx_entity_link_from ON entity_link(from_type, from_id);
CREATE INDEX IF NOT EXISTS idx_entity_link_to ON entity_link(to_type, to_id);

CREATE TABLE IF NOT EXISTS time_session (
    id TEXT PRIMARY KEY,
    workspace_id TEXT,
    task_id TEXT,
    session_type TEXT NOT NULL DEFAULT 'focus',
    started_at TEXT NOT NULL,
    ended_at TEXT,
    planned_minutes INTEGER,
    actual_seconds INTEGER,
    note TEXT,
    FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE SET NULL,
    FOREIGN KEY (task_id) REFERENCES task(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS activity_event (
    id TEXT PRIMARY KEY,
    workspace_id TEXT,
    event_type TEXT NOT NULL,
    entity_type TEXT,
    entity_id TEXT,
    title TEXT,
    metadata_json TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (workspace_id) REFERENCES workspace(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS developer_asset (
    id TEXT PRIMARY KEY,
    parent_id TEXT,
    asset_type TEXT NOT NULL,
    name TEXT NOT NULL,
    status TEXT,
    uri TEXT,
    content TEXT,
    metadata_json TEXT,
    is_favorite INTEGER NOT NULL DEFAULT 0 CHECK (is_favorite IN (0,1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    archived_at TEXT,
    FOREIGN KEY (parent_id) REFERENCES developer_asset(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS ai_thread (
    id TEXT PRIMARY KEY,
    title TEXT,
    scope TEXT NOT NULL CHECK (scope IN ('task','workspace','knowledge','global')),
    workspace_id TEXT,
    task_id TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ai_message (
    id TEXT PRIMARY KEY,
    thread_id TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('system','user','assistant','tool')),
    content TEXT NOT NULL,
    context_snapshot_json TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (thread_id) REFERENCES ai_thread(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS app_setting (
    setting_key TEXT PRIMARY KEY,
    value_json TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
