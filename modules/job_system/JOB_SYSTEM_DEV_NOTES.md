# Job System Dev Notes

Module: `Yoko-Fantasy` job transition framework
Status: test framework only (no numerical gameplay effects yet)

## Toggle
1. File: `extensions/jobs/job_system.gd`
2. Flag: `ENABLE_JOB_SYSTEM`
3. Set to `false` to disable all transition behavior quickly for regression tests.

## Naming Rules
1. IDs use lowercase snake_case.
2. Upgrade id format:
- `my_id`: `upgrade_fantasy_job_<job_id>`
- `upgrade_id`: `fantasy_job_<job_id>`
3. Translation key format:
- name: `UPGRADE_FANTASY_JOB_<JOB_KEY>`
- description: `EFFECT_FANTASY_JOB_<JOB_KEY>_DESC`

## Job State Keys
1. `Utils.fantasy_job_stage_hash`
2. `Utils.fantasy_job_pending_tier_hash`
3. `Utils.fantasy_job_family_hash`
4. `Utils.fantasy_job_tier1_id_hash`
5. `Utils.fantasy_job_tier2_id_hash`

## Entry Points
1. Wave trigger queue:
- `extensions/main.gd` -> `_on_WaveTimer_timeout` -> `_fantasy_queue_job_upgrades()`
2. Upgrade pool override:
- `extensions/item_service.gd` -> `get_upgrades(...)`
3. State apply effect:
- `extensions/effects/job/job_select_effect.gd`

## Folder Layout
1. Job system logic:
- `extensions/jobs/`
- `extensions/effects/job/`
2. Job upgrade resources:
- `content/upgrades/jobs/<job_id>/`
3. Module docs:
- `modules/job_system/`
