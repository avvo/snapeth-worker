defmodule Snapeth.Storage do
  require Logger

  def persist_leaderboard(state) do
    Application.get_env(:snapeth, :bucket_name)
    |> ExAws.S3.put_object(
      Application.get_env(:snapeth, :leaderboard_data_file),
      Poison.encode!(state)
    ) |> ExAws.request()
  end

  def fetch_leaderboard() do
    Application.get_env(:snapeth, :bucket_name)
    |> ExAws.S3.get_object(Application.get_env(:snapeth, :leaderboard_data_file))
    |> ExAws.request()
    |> case do
      {:ok, %{body: body}} ->
        Poison.decode!(body)
      error ->
        Logger.error "Error loading leaderboard! #{inspect error}"
    end
  end
end
