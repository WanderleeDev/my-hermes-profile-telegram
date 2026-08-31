# Live Model Verification Data

## Verified free+vision models (2026-07-20)
Queried via `GET https://openrouter.ai/api/v1/models` — models with `image` in `architecture.input_modalities`:

| Model ID | Context | Notes |
|----------|---------|-------|
| `google/gemma-4-26b-a4b-it:free` | 262K | Google, strong reasoning |
| `google/gemma-4-31b-it:free` | 262K | Google, best free vision |
| `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free` | 256K | NVIDIA, multi-modal |
| `nvidia/nemotron-3.5-content-safety:free` | 128K | NVIDIA, moderation only |
| `nvidia/nemotron-nano-12b-v2-vl:free` | 128K | NVIDIA, vision-language |

## Disappeared free models (confirmed 404 in July 2026)
- `qwen/qwen2.5-vl-3b-instruct:free`
- `google/gemini-2.5-pro-exp-03-25:free`
- `moonshotai/kimi-vl-a3b-thinking:free`

## Agnes AI available models (verified 2026-07-20)
Queried via `GET https://apihub.agnes-ai.com/v1/models`:
- `agnes-1.5-flash`
- `agnes-video-v2.0`
- `agnes-image-2.1-flash` ← correct name (has `-flash` suffix)
- `agnes-2.0-flash`
- `agnes-image-2.0-flash`

## Common mistakes
- Model name `agnes-image-2.1` is WRONG — must be `agnes-image-2.1-flash`
- Using `patch()` on config.yaml triggers security refusal — use `hermes config set` or terminal
- Cron jobs created before model change will drift and skip — always pin model in cronjob