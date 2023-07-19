class GPTClient
  EMBEDDINGS_MODEL = "text-embedding-ada-002"
  GEN_MODEL = "gpt-3.5-turbo"

  def initialize
    @client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
  end

  def chat(message, add_prompt: false, model: GEN_MODEL)
    Timeout.timeout(30) do
      message = [{ role: "user", content: message }] if message.is_a?(String)
      message = PROMPT + message if add_prompt

      response =
        @client.chat(
          parameters: {
            model: model,
            messages: message,
            temperature: 0.5
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
