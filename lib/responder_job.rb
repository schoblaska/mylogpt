class ResponderJob
  include Sidekiq::Worker

  def perform(prompt, response_url)
    tweet = generate_tweet(prompt)

    HTTParty.post(
      response_url,
      body: tweet_block(tweet).to_json,
      headers: {
        "Content-Type" => "application/json"
      }
    )
  end

  private

  def tweet_block(tweet)
    {
      response_type: "in_channel",
      delete_original: true,
      blocks: [
        { type: "section", text: { type: "mrkdwn", text: tweet } },
        {
          type: "context",
          elements: [
            {
              type: "image",
              image_url: "https://schoblaska.org/assets/twitter.png",
              alt_text: "Twitter logo"
            },
            { type: "mrkdwn", text: "Twitter | #{now}" }
          ]
        }
      ]
    }
  end

  def chat(client, messages)
    Timeout.timeout(10) do
      response =
        client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: messages,
            temperature: 0.5
          }
        )

      response.dig("choices", 0, "message", "content")
    end
  end

  def generate_tweet(phrase)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])

    response = chat(client, PROMPT + [{ role: "user", content: phrase }])

    if response[0] =~ /[A-Z]/
      # the real mylo doesn't start sentences with a capital letter.
      # we got back a generic ChatGPT response. ask it to try harder.
      response =
        chat(
          client,
          PROMPT +
            [
              { role: "user", content: phrase },
              { role: "assistant", content: response },
              {
                role: "user",
                content:
                  "Generate a new response that matches the examples instead of being generic. Remember not to start a sentence with a capital letter."
              },
              { role: "user", content: phrase }
            ]
        )
    end

    response
  end

  def now
    TZInfo::Timezone
      .get("America/Chicago")
      .now
      .strftime("%b %-d, %Y at %-l:%M %p")
  end
end
