# Verify a live free OpenRouter model with vision (don't trust static lists)

`:free` model IDs churn constantly — prior IDs like `qwen/qwen2.5-vl-3b-instruct:free`
and `google/gemini-2.5-pro-exp-03-25:free` returned HTTP 404 in July 2026.

## Recipe (verified 2026-07-18)
1. Read `OPENROUTER_API_KEY` from the Hermes profile `.env` (mask it, never print it).
2. `GET https://openrouter.ai/api/v1/models` with header `Authorization: Bearer <key>`.
3. Filter `data[]` where `":free" in id` AND `"image" in architecture.input_modalities`.
4. Recommend the one with the largest `context_length` among capable vision models.
   As of 2026-07-18 the best free vision pick was `google/gemma-4-31b-it:free` (262K).

## In Hermes / execute_code
```python
import json, urllib.request, re
env = open("/home/ubuntu/.hermes/profiles/telegram-bot/.env").read()
key = re.search(r"^OPENROUTER_API_KEY[ \t]*=(.*)$", env, re.M).group(1).split("#")[0].strip()
req = urllib.request.Request("https://openrouter.ai/api/v1/models",
                             headers={"Authorization": f"Bearer {key}"})
d = json.loads(urllib.request.urlopen(req, timeout=20).read())
for m in d["data"]:
    if ":free" in m["id"] and "image" in m.get("architecture",{}).get("input_modalities",[]):
        print(m["id"], m.get("context_length"))
```
5. Apply with `hermes config set model.default <id>` (needs a gateway restart to take
   effect — USER must run `hermes gateway restart` from SSH; agent can't from the chat).
