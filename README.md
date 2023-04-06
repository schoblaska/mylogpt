# MyloGPT
To run MyloGPT locally:

```bash
OPENAI_ACCESS_TOKEN=asdf1234 ruby app.rb
```

```bash
PROMPT="chicago vs nyc"

curl -X POST "http://localhost:4567/tweet" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "text=$PROMPT" | \
  jq '.blocks[] | select(.type == "section") | .text.text'

# "nyc is like if chicago and LA had a baby then that baby was raised by wolves"
```
