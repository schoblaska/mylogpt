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
* [ ] Use GPT-4 (if avail - make a config option) for prompt smoothing step
* [ ] Have a number of GPT-4 "tokens" per day. Each usage has some weighted percent (decays with each use) of using GPT-4
  * [ ] How much more expensive is it vs current model?
  * [ ] Track in Redis with an incrementing {date: num} key / val
  * [ ] Add a stamp to output signature if it came from GPT-4 (in the Twitter "context" block)
  * [ ] Mylo and Joey get extra / unlimited tokens
* [ ] Use different tweets for few-shot learning in prompt each time
  * [ ] Build a vector database of Mylo's tweets (maybe using [pgvector](https://github.com/pgvector/pgvector) and [neighbor](https://github.com/ankane/neighbor))
  * [ ] Generate embedding for user prompt and pull top 20 tweets
* [ ] Simulate image tweets with DALL-E
  * [ ] Add labels for tweets with images
  * [ ] Replace image URL in completion with `[img: dall-e prompt that would generate something approximating this image]`
  * [ ] Before sending tweet to Slack, check for `[img: ]` block; if found, send prompt to DALL-E and use generated image to replace block

### Embeddings
This didn't quite work like I hoped. I think I need to combine the earlier
approach of "user prompt / assistant tweet" example messages, but using a set
of tweets selected by vector similarity to prompt.

That means that I'm back to needing labeled data, so I need to get ChatGPT to
generate labels for me. Take prompts that people have used in Kenna Slack, pick
some example tweets from the dataset and give them similar labels, then let
ChatGPT generate the remainder. Generate 100 or so labels at a time and check
them for quality. For each prompt for a new label, select a set of n random
labeled tweets from the dataset so that I'm not biasing ChatGPT with the same
examples over and over again.
