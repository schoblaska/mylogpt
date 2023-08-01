# MyloGPT
To run MyloGPT locally, `cp .env.example .env` and replace the placeholder values. Then:

```bash
docker-compose up --build
```

```bash
PROMPT="chicago bars"
RESPONSE_URL="http://mylogpt-echo:8080"

curl -X POST "http://localhost:4567/tweet" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "response_url=$RESPONSE_URL&text=$PROMPT"
```

## TODO
* [ ] Simulate image tweets with DALL-E
  * [ ] Add labels for tweets with images
  * [ ] Replace image URL in completion with `[img: dall-e prompt that would generate something approximating this image]`
  * [ ] Before sending tweet to Slack, check for `[img: ]` block; if found, send prompt to DALL-E and use generated image to replace block
