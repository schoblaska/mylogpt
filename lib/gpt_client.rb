class GPTClient
  EMBEDDINGS_MODEL = "text-embedding-ada-002"
  CHAT_MODEL = "chatgpt-4o-latest"
  MAX_TOKENS = 100
  DEFAULT_TEMPERATURE = 1
  MYLO_USER_ID = "U01695SLPDJ"
  REDIS = RedisClient.new(url: ENV["REDIS_URL"])

  def initialize
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
  end

  def chat(
    messages,
    prompt: nil,
    model: CHAT_MODEL,
    temperature: DEFAULT_TEMPERATURE
  )
    messages = [{ role: "user", content: messages }] if messages.is_a?(String)
    messages = prompt + messages if prompt

    Timeout.timeout(30) do
      response =
        @client.chat(
          parameters: {
            model: model,
            messages: messages,
            temperature: temperature,
            max_tokens: MAX_TOKENS
          }
        )

      response.dig("choices", 0, "message", "content")
    end
  end

  def embedding(input)
    response =
      @client.embeddings(parameters: { model: EMBEDDINGS_MODEL, input: input })

    response.dig("data", 0, "embedding")
  end
end
