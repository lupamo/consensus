CREATE TABLE IF NOT EXISTS settlements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD' CHECK (char_length(currency) = 3),
  total_cents BIGINT NOT NULL DEFAULT 0 CHECK (total_cents >= 0),
  status TEXT NOT NULL DEFAULT 'created' CHECK (status IN (
    'created','funded','collecting_evidence','negotiating',
    'awaiting_approval','approved','paying','settled','failed')),
  policy_json JSONB NOT NULL DEFAULT '{}',
  paypal_order_id TEXT UNIQUE,
  payout_batch_id TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS participants (
  id TEXT PRIMARY KEY,
  settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role TEXT,
  agent_style TEXT NOT NULL DEFAULT 'fair',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (settlement_id, email)
);

CREATE TABLE IF NOT EXISTS evidence (
  id TEXT PRIMARY KEY,
  settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
  participant_id TEXT REFERENCES participants(id),
  kind TEXT NOT NULL,
  source TEXT,
  raw_text TEXT,
  extracted_json JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS claims (
  id TEXT PRIMARY KEY,
  settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
  participant_id TEXT NOT NULL REFERENCES participants(id),
  statement TEXT NOT NULL,
  evidence_id TEXT REFERENCES evidence(id),
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open','disputed','accepted')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rounds (
  id TEXT PRIMARY KEY,
  settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
  round_no INT NOT NULL CHECK (round_no >= 1),
  proposal_json JSONB,
  transcript_json JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (settlement_id, round_no)
);

CREATE TABLE IF NOT EXISTS allocations (
  id TEXT PRIMARY KEY,
  settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
  participant_id TEXT NOT NULL REFERENCES participants(id),
  amount_cents BIGINT NOT NULL CHECK (amount_cents >= 0),
  weight NUMERIC CHECK (weight >= 0 AND weight <= 1),
  reason_text TEXT,
  round_no INT,
  is_final BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


CREATE UNIQUE INDEX IF NOT EXISTS allocations_one_final
  ON allocations (settlement_id, participant_id) WHERE is_final;

CREATE TABLE IF NOT EXISTS payout_items (
  id TEXT PRIMARY KEY,
  settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
  participant_id TEXT NOT NULL REFERENCES participants(id),
  allocation_id TEXT NOT NULL REFERENCES allocations(id),
  amount_cents BIGINT NOT NULL CHECK (amount_cents >= 0),
  paypal_item_id TEXT,
  status TEXT NOT NULL DEFAULT 'pending', 
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (settlement_id, participant_id) 
);

CREATE TABLE IF NOT EXISTS approvals (
  id TEXT PRIMARY KEY,
  settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
  participant_id TEXT NOT NULL REFERENCES participants(id),
  decision TEXT NOT NULL CHECK (decision IN ('approve','reject')),
  comment TEXT,
  at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS evidence_settlement_idx    ON evidence (settlement_id);
CREATE INDEX IF NOT EXISTS claims_settlement_idx      ON claims (settlement_id);
CREATE INDEX IF NOT EXISTS allocations_settlement_idx ON allocations (settlement_id);
CREATE INDEX IF NOT EXISTS approvals_settlement_idx   ON approvals (settlement_id);