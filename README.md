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

## TODO
* [ ] Use official Docker repo [login action](https://github.com/docker/login-action)
* [ ] Explore creating a fine-tuned model instead of using few-shot inline prompt
  * [ ] Automate tweet scraping and labeling (put in SQLite or something). Support multiple labels on each tweet (each label is a different training example)
    * [ ] Separate repo for managing data and tooling
* [ ] Better response filtering. Eg, reject anything that includes "AI language model"
  * [ ] Reject capitalized responses without calling out the grammar (ChatGPT just gives the same response, but starting with a lowercase)
  * [ ] Instead of retrying, ask untrained GPT-3 to rephrase the prompt? Someone is probably asking a complex question rather than providing a topic. "Extract the main topics from this phrase and return them, separated by spaces"
    * [ ] Maybe just do this for all prompts longer than a few words
* [ ] Fix intermittent "invalid blocks" error
* [ ] Turn into an app?
