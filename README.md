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
* [ ] Use official Docker repo [login action](https://github.com/docker/login-action)
* [ ] Explore creating a fine-tuned model instead of using few-shot inline prompt
  * [ ] Automate tweet scraping and labeling (put in SQLite or something). Support multiple labels on each tweet (each label is a different training example)
    * [ ] Separate repo for managing data and tooling
* [ ] Fix intermittent "invalid blocks" error (if this is even still happening...)
* [ ] Turn into an app?
