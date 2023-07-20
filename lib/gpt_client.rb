class GPTClient
  EMBEDDINGS_MODEL = "text-embedding-ada-002"
  CHEAP_MODEL = "gpt-3.5-turbo"
  GOOD_MODEL = "gpt-4"
  GOOD_MODEL_PERCENTAGE = 0.2
  MAX_TOKENS = 100

  def initialize
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
  end

  def chat(messages, prompt: nil, model: nil)
    model ||= rand < GOOD_MODEL_PERCENTAGE ? GOOD_MODEL : CHEAP_MODEL
    messages = [{ role: "user", content: messages }] if messages.is_a?(String)
    messages = prompt + messages if prompt

    Timeout.timeout(30) do
      response =
        @client.chat(
          parameters: {
            model: model,
            messages: messages,
            temperature: 1,
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
