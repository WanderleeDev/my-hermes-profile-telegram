---
name: agnes-video-integration
description: "Trigger: agnes video, video generate, agnes-video, animate image. Use Agnes AI for video generation from images with R2 storage."
license: Apache-2.0
metadata:
  author: "xam"
  version: "2.0"
---

# Agnes Video Integration

## Activation Contract

Load when: user requests video generation via Agnes AI, or when `video_generate`/`video_gen` is called.

## IMPORTANT: Use Plugin Only

**CRITICAL:** The skill must NEVER call the Agnes API directly.

All video generation must go through the plugin at `~/.hermes/plugins/video_gen/agnes/__init__.py`.

The plugin handles:
- Constructing the correct API payload (including `mode` parameter)
- Auto-detecting mode based on input (`"reference"` when images provided, `"text"` otherwise)
- Polling for completion
- Uploading to R2

### Why use the plugin?
1. The plugin knows the correct API schema (e.g., `mode` parameter is required)
2. The plugin handles errors and rate limits
3. The plugin manages R2 uploads automatically
4. The plugin resolves local paths to public URLs via registry

**Never** construct API requests manually — always call the plugin.

ALWAYS ask for explicit approval ("visto bueno") BEFORE executing any action that:
- Generates videos
- Runs terminal commands
- Writes files
- Modifies configuration

Read-only checks (listing files, checking config) are OK without approval.

## Image Registry (for video input)

Videos are generated from images. The image must have a public URL.
Check `~/.hermes/image_registry.json` for registered images:
```json
{
  "local": { ... },
  "r2": {
    "images/20260827_xxx.png": {
      "url": "https://media.wanderlee.site/images/xxx.png",
      "local_path": "/home/ubuntu/.hermes/cache/images/...",
      "prompt": "...",
      "created": "..."
    }
  }
}
```

### Using registered images in video generation:
- Pass local path as `image_url` → plugin checks registry for public URL
- If no public URL found, returns error (video API requires public URLs)
- Solution: Re-generate image with `storage="r2"` first

## Model Selection (Decision Logic for AI)

The skill decides which model to use based on prompt context. The plugin receives the model ID from the skill, not vice versa.

### Video Models
| When to Use | Model | Why |
|-------------|-------|-----|
| Legacy API, v2 reference | `agnes-video-v2.0` | Older but stable |
| Professional quality, cinematic, paid | `agnes-video-2.5` | Best quality |
| Default (free, fast) | `agnes-video-2.5-flash` | Good enough for most cases |

**Decision flow:**
1. Read user prompt
2. Check for quality keywords (cinematic, professional) → use 2.5 if available
3. Otherwise → use 2.5-flash (free default)
4. Pass chosen model to plugin via `model` parameter

### Model-Specific API Parameters

**IMPORTANT:** Each Agnes video model uses different API parameters. The plugin must route correctly.

| Model | `mode` (text-only) | `mode` (1 image) | `mode` (multi image) | Payload key |
|-------|-------------------|------------------|---------------------|-------------|
| `agnes-video-v2.0` | `"ti2vid"` | `"ti2vid"` | `"multi_reference"` | `"image"` (singular, list) |
| `agnes-video-2.5` | `"text"` | `"reference"` | `"reference"` | `"images"` (plural, list) |
| `agnes-video-2.5-flash` | `"text"` | `"reference"` | `"reference"` | `"images"` (plural, list) |

**Example payload for `agnes-video-v2.0`:**
```json
{
  "model": "agnes-video-v2.0",
  "prompt": "...",
  "seconds": "12",
  "mode": "ti2vid",
  "size": "720P",
  "aspect_ratio": "16:9",
  "image": ["https://..."]
}
```

**Example payload for `agnes-video-2.5-flash`:**
```json
{
  "model": "agnes-video-2.5-flash",
  "prompt": "...",
  "seconds": "12",
  "mode": "reference",
  "size": "720P",
  "aspect_ratio": "16:9",
  "images": ["https://..."]
}
```

### Important
- Do NOT hardcode model selection in the plugin
- The skill decides based on full context
- Plugin just executes with whatever model ID it receives

## Execution Strategy

Video generation is a long-running blocking operation (30-120s). 
ALWAYS use `delegate_task` to avoid blocking the main chat.

### Why delegate_task?
- Plugin runs synchronous polling (2min timeout)
- Blocks the main chat during generation
- Subagent handles polling independently
- Result returns when ready

### How to execute (IMPORTANT)

**DO NOT use `video_generate` tool** — it's NOT available in subagents. Use the plugin via Python directly.

**Copy-paste this exact command (just change prompt, image_url, r2_name):**
```bash
cd ~/.hermes && ~/.hermes/hermes-agent/venv/bin/python -c "
import sys, json
sys.path.insert(0, '.')
from plugins.video_gen.agnes import AgnesVideoGenProvider

p = AgnesVideoGenProvider()
r = p.generate(
    prompt='YOUR_PROMPT_HERE',
    model='agnes-video-2.5-flash',
    image_url='https://media.wanderlee.site/images/XXX.png',  # optional
    duration=12,
    aspect_ratio='16:9',
    r2_name='YOUR_NAME_HERE'  # optional, snake_case
)
print(json.dumps(r, indent=2))
"
```

**If you get 429 (rate limit):** wait 60 seconds, then retry. Agnes allows only ~2 video requests per minute.

**If polling times out (120s):** the task is still processing. Wait 60s and poll manually:
```bash
curl -s 'https://apihub.agnes-ai.com/agnesapi?video_id=TASK_ID&model_name=agnes-video-2.5-flash'
```

**After video completes:** download and upload to R2 with custom name:
```bash
cd ~/.hermes && ~/.hermes/hermes-agent/venv/bin/python -c "
import httpx, os, time, boto3
from botocore.config import Config

# Download video
video_url = 'AGNES_CDN_URL_HERE'
r = httpx.get(video_url, timeout=120)
video_data = r.content

# Upload to R2
s3 = boto3.client('s3', endpoint_url=f'https://{os.environ[\"R2_ACCOUNT_ID\"]}.r2.cloudflarestorage.com', aws_access_key_id=os.environ['R2_ACCESS_KEY_ID'], aws_secret_access_key=os.environ['R2_SECRET_ACCESS_KEY'], region_name='auto', config=Config(signature_version='s3v4'))
key = f'videos/YOUR_NAME_HERE_{time.strftime(\"%Y%m%d_%H%M%S\")}.mp4'
s3.put_object(Bucket='hermes-video-db', Key=key, Body=video_data, ContentType='video/mp4')
print(f'https://video.wanderlee.site/{key}')
"
```

**Key paths:**
- Python: `~/.hermes/hermes-agent/venv/bin/python`
- Plugin: `~/.hermes/plugins/video_gen/agnes/__init__.py`
- Registry: `~/.hermes/image_registry.json`
- R2 bucket: `hermes-video-db`, domain: `video.wanderlee.site`

### When NOT to use delegate_task?

### Naming Convention for R2

When the user does NOT specify a custom name, generate a snake_case name from the first few words of the prompt + timestamp.

**Format:** `{snake_case_description}_{YYYYMMDD}_{HHMMSS}`

**Examples:**
- Prompt: "A cat skiing on Everest" → name: `cat_skiing_everest_20260828_202621`
- Prompt: "Un perro siendo abducido" → name: `perro_abducido_20260828_191255`
- Prompt: "cyberpunk city at night" → name: `cyberpunk_city_night_20260828_153045`

**Rules:**
- Take first 2-4 meaningful words from prompt
- Convert to lowercase, replace spaces with underscores
- Remove special characters, accents (á→a, é→e, etc.)
- Append `_YYYYMMDD_HHMMSS`
- Max 60 characters for the name part

**Pass the name to the plugin as `r2_name`** — the plugin concatenates it with the timestamp automatically.

### When NOT to use delegate_task?
- Image generation (`image_gen/agnes`) — fast (timeout 30s), no polling needed
- Checking plugin availability
- Listing models

## Timeouts

| Type | Timeout | Behavior |
|------|---------|----------|
| Video | 360s | Poll every 60s (rate limit: ~2 req/min), show progress every ~60s |

> **Note on polling interval:** Agnes video API has a rate limit of ~2 req/min.
> The plugin polls every 60s to avoid 429 errors. With timeout=360s, you get up to
> 6 chances to detect completion. Videos typically take 3-4 minutes in practice.
> For images, no polling — single request with 30s timeout.

## Usage Examples

### Generate video from image
```
Animate image https://media.wanderlee.site/images/xxx.png for 4 seconds
# Returns video URL
```

### Generate video with specific duration
```
Generate video from https://media.wanderlee.site/images/xxx.png seconds=8
# 8 second video
```

### Generate video with specific model
```
Generate video model=agnes-video-2.5 prompt="cinematic drone shot"
# Use higher quality model
```

### Generate video from local image path
```
Generate video from /home/ubuntu/.hermes/images/photo.png
# Plugin looks up registry for public URL
# If not found, suggests uploading to R2 first
```

## Execution Steps

### Video Generation
1. Skill reads prompt and decides model (see Model Selection above)
2. Skill validates input image has public URL
3. If input is local path → check registry for public URL
4. If no public URL → error, suggest re-generating image with storage=r2
5. **Call the plugin** — do NOT construct API requests manually
6. Plugin handles: mode detection, API call, polling, R2 upload
7. Plugin returns video URL (R2 or Agnes CDN)
8. Register in `~/.hermes/image_registry.json`
9. Return video URL to user

### Pitfalls

1. **Always use the plugin** — never call the API directly
2. Video API only accepts PUBLIC URLs, not local paths or base64
3. Ensure input image has permanent URL (R2 preferred over temporary Agnes URL)
4. Video duration limited to 4-12 seconds
5. Max 5 reference images per video
6. Size must be exactly "720P" for flash models
7. **Mode parameter is required** — plugin sets it automatically:
   - `"reference"` when providing an image URL
   - `"text"` for text-only generation
8. API key must be read from config.yaml fallback if .env is missing/truncated
9. Model IDs require `-flash` suffix (e.g., `agnes-video-2.5-flash` not `agnes-video-2.5`)
10. **Rate limit: 2 video requests per minute** — plugin handles retries automatically
11. **Polling 429 is normal** — if you get 429 during polling, the task is still processing; wait and retry
12. **Config uses env vars** — `config.yaml` uses `${AGNES_API_KEY}` syntax, not hardcoded keys

## Global Configuration

### API Credentials
Stored in `~/.hermes/.env`:
```
AGNES_API_KEY=***
```

### R2 Credentials
Stored in `~/.hermes/.env`:
```
R2_ACCOUNT_ID=2884c63d70470fc763e5bc49f7259994
R2_ACCESS_KEY_ID=***
R2_SECRET_ACCESS_KEY=***
```

### Bucket Structure
```
hermes-video-db/     → video.wanderlee.site/
└── videos/
    └── YYYYMMDD_hash.mp4
```

## References

- Plugin: `~/.hermes/plugins/video_gen/agnes/__init__.py`
- Registry: `~/.hermes/image_registry.json`
- Env: `~/.hermes/.env` (AGNES_API_KEY, R2 credentials)
- `agnes-r2-storage/references/r2-custom-domain.md` — Custom domain setup
- `agnes-r2-storage/references/r2-setup.md` — Setup guide and portability info
