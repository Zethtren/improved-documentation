defmodule PhoenixDashboard.OllamaClient do
  @moduledoc "Client for Ollama API (embeddings and generation)"

  @base_url "http://localhost:11434"

  def embed(text) when is_binary(text) do
    case Req.post("#{base_url()}/api/embeddings",
      json: %{model: "nomic-embed-text", prompt: text}
    ) do
      {:ok, %{status: 200, body: %{"embedding" => embedding}}} ->
        {:ok, embedding}
      {:ok, %{body: body}} ->
        {:error, "Ollama error: #{inspect(body)}"}
      {:error, reason} ->
        {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  def generate(prompt, opts \\ []) do
    model = Keyword.get(opts, :model, "llama3.1:8b")
    case Req.post("#{base_url()}/api/generate",
      json: %{model: model, prompt: prompt, stream: false},
      receive_timeout: 60_000
    ) do
      {:ok, %{status: 200, body: %{"response" => response}}} ->
        {:ok, String.trim(response)}
      {:ok, %{body: body}} ->
        {:error, "Ollama error: #{inspect(body)}"}
      {:error, reason} ->
        {:error, "Connection failed: #{inspect(reason)}"}
    end
  end

  defp base_url do
    Application.get_env(:phoenix_dashboard, :ollama_url, @base_url)
  end
end
