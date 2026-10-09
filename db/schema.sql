CREATE TABLE IF NOT EXISTS settlements (
	id TEXT PRIMARY KEY,
	title TEXT NOT NULL,
	currency TEXT NOT NULL DEFAULT 'USD',
	total_cents BIGINT NOT NULL DEFAULT 0,
	status TEXT NOT NULL DEFAULT 'created',
	policy_json JSONB NOT NULL DEFAULT '{}',
	paypal_order_id TEXT,
	payout_batch_id TEXT,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS participants (
	id TEXT PRIMARY KEY,
	settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
	name TEXT NOT NULL,
	email TEXT NOT NULL,
	role TEXT,
	agent_style TEXT NOT NULL DEFAULT 'fair'
);

CREATE TABLE IF NOT EXISTS evidence (
	id TEXT PRIMARY KEY,
	settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
	participants_id TEXT REFERENCES participants(id),
	kind TEXT NOT NULL,
	source TEXT,
	raw_text TEXT,
	extracted_json JSONB
);

CREATE TABLE IF NOT EXISTS claims (
	id TEXT PRIMARY KEY,
	settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
	participant_id TEXT NOT NULL REFERENCES participants(id),
	statement TEXT NOT NULL,
	evidence_id TEXT REFERENCES evidence(id),
	status TEXT NOT NULL DEFAULT 'open'
);

CREATE TABLE IF NOT EXISTS rounds (
	id TEXT PRIMARY KEY,
	settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
	round_no INT NOT NULL,
	proposal_json JSONB,
	transcript_json JSONB
);

CREATE TABLE IF NOT EXISTS allocations  (
	id TEXT PRIMARY KEY,
	setlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
	participant_id TEXT NOT NULL REFERENCES participants(id),
	amount_cents BIGINT NOT NULL,
	weight NUMERIC,
	reason_text TEXT,
	round_no INT,
	is_final BOOLEAN NOT NULL DEFAULT false,
);

CREATE TABLE IF NOT EXISTS payout_items (
  id TEXT PRIMARY KEY,
  settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
  participant_id TEXT NOT NULL REFERENCES participants(id),
  amount_cents BIGINT NOT NULL,
  paypal_item_id TEXT,
  status TEXT NOT NULL DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS approvals (
  id TEXT PRIMARY KEY,
  settlement_id TEXT NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
  participant_id TEXT NOT NULL REFERENCES participants(id),
  decision TEXT NOT NULL,
  comment TEXT,
  at TIMESTAMPTZ NOT NULL DEFAULT now()
);

