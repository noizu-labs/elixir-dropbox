# Threat Model — noizu_dropbox

## Overview

`noizu_dropbox` is a client library, not a deployed service: it holds no
listeners, no data stores of its own, and no privileged position. The **crown
jewels are Dropbox credentials** (access/refresh tokens, app secret) and the
**user's Dropbox data** in transit. The library's job is to keep secrets out
of logs/commits, authenticate calls only to Dropbox over TLS, and fail safely
when the remote side misbehaves. The deployed perimeter (ingress, pods,
secret syncing) belongs to the embedding app — primarily
`Portfolio/Apps/AI/dropbox-mcp` — and is modeled there, not here.
Grounding: [PROJ-ARCH.md](PROJ-ARCH.md) · [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## Attack Surface

```mermaid
graph LR
    Caller[Embedding app / dropbox-mcp] -->|opts + %Client{}| LIB[noizu_dropbox]
    LIB -->|Bearer / Basic + JSON| API[api.dropboxapi.com]
    LIB -->|Bearer + binary| CBX[content.dropboxapi.com]
    LIB -->|form POST| OAUTH[oauth2 token endpoint]
    Response[Dropbox responses] -->|JSON / headers| LIB
    ENV[:noizu_dropbox app env] -.config + request_fun.-> LIB
    SECRETS[Infisical / env] -.-> ENV
```

Trust boundary crossings: caller → library (opts/env), library → Dropbox
(egress TLS), Dropbox → library (response parsing), app env → transport
(`request_fun` hook).

## Vulnerability Register

| ID | Severity | STRIDE | Component | Status |
|----|----------|--------|-----------|--------|
| T-001 | High | Info disclosure | Credentials in `config :noizu_dropbox` / `%Client{}` | Mitigated by convention: all keys default `nil`, secrets never committed; supply via env/runtime (Infisical) |
| T-002 | Medium | DoS | `:atoms` decode mode creates atoms from response keys (`HTTP.decode_json`) | Partial: default `:atoms` on `rpc`; a hostile/compromised endpoint could exhaust the atom table. Use `:strings`/`:raw` for untrusted responses |
| T-003 | Low | Spoofing | 401 auto-refresh + retry (`maybe_refresh_retry`) | Mitigated: single retry, bearer-only, guarded by `__retried_401` flag — no refresh loops |
| T-004 | Medium | Tampering / EoP | `request_fun` app-env hook replaces the transport process-wide | Accepted: test hook; any attacker who can set app env already owns the BEAM |
| T-005 | Low | Info disclosure | `%Error{body}`/`raw` fields retain full response bodies — may surface in logs | Open (accepted): callers must not `inspect` errors into shared logs |
| T-006 | Low | Spoofing | No certificate pinning; standard CA validation only | Accepted: standard for API clients; MITM requires CA compromise |
| T-007 | Low | Info disclosure | OAuth secret sent in Basic header XOR form body, never both | Mitigated by code (`maybe_secret`) |
| T-008 | Low | DoS | No 429/backoff handling — only 401 retries | Open: callers must implement rate-limit backoff |

## Mitigation Coverage

5 mitigated · 2 partial/accepted · 2 open (T-005 log hygiene — caller-side;
T-008 backoff — caller-side). No in-repo ticket tracking; revisit when the
client gains retry/rate-limit support.

## Residual Risk

Response-key atomization (T-002) is the sharpest edge: probability is low
(Dropbox is the peer) but impact is BEAM-wide. Accepted because endpoint
modules decode known shapes; untrusted-adjacent consumers should pass
`decode: :strings`. Everything else reduces to caller-side secret hygiene
and log discipline.
