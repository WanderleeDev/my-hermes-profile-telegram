# OCI Always Free ARM change — June 2026

## The change (confirmed by multiple outlets, July 2026)
- **Effective date:** 2026-06-15
- **Before:** 4 OCPUs + 24 GB RAM (Ampere A1 Always Free total pool)
- **After:** 2 OCPUs + 12 GB RAM
- Done quietly: no blog post, no email, no in-console notice. Discovered via documentation diffs and instances shutting down.
- Sources: InfoQ (infoq.com/news/2026/07/oracle-cloud-free-tier-limits), Linuxiac, TerminalBytes, daily.dev — all July 2026.

## Grandfathering
- Pre-existing 4/24 instances were *generally* respected, but there were scattered reports of auto-shutdowns and OCI support agents giving contradictory answers about billing the overage. Not a clean, guaranteed grandfather.
- Instances created on/after 2026-06-15 are born at 2/12 and are fully compliant.

## Practical implications
- A single 2 OCPU / 12 GB A1 VM now consumes 100% of the free ARM pool. You can no longer spin up a second free ARM VM alongside a full-size one.
- To get more ARM capacity: convert account to Pay-As-You-Go and pay the small overage (cents/hour per extra A1 OCPU), or optimize the single VM.
- Block Volume Always Free: up to 200 GB total (unchanged). A ~193 GB boot volume fits within this.

## Egress (unchanged by this)
- ~10 TB/month free outbound in most commercial regions; ingress always free; overage ~$0.0085/GB.

## Lesson
Always re-verify OCI free-tier numbers with a live web search before quoting — Oracle has a track record of changing them without announcement.
