# THREAT-MODEL (summary)

Client library — no listeners or own stores. Assets: Dropbox credentials and
user Dropbox data in transit. Deployed perimeter modeled by the embedding app
(dropbox-mcp), not here.

Boundaries: caller → lib (opts/env); lib → Dropbox (TLS egress); responses →
parser; app env `request_fun` → transport.

Register: 8 entries — T-001 credential storage (mitigated: nil defaults,
env-only secrets) · T-002 atom-table exhaustion via `:atoms` decode (partial;
use `:strings` for untrusted) · T-003 401 refresh loop (mitigated: single
retry) · T-004 `request_fun` transport hook (accepted test hook) · T-005 raw
bodies in `%Error{}` may leak to logs (open, caller-side) · T-006 no cert
pinning (accepted) · T-007 OAuth secret Basic-XOR-body (mitigated) · T-008 no
429 backoff (open, caller-side).

Residual: T-002 is the sharpest edge — low probability (Dropbox is the peer),
BEAM-wide impact.

Full detail: [THREAT-MODEL.md](THREAT-MODEL.md).
