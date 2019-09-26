defmodule Snapeth.Storage do
  require Logger
  use Timex

  def leaderboard_filename() do
    now = Timex.iso_week(Timex.today)
    "#{elem(now,1)}-leaderboard.json"
  end

  def persist_leaderboard(state) do
    Application.get_env(:snapeth, :bucket_name)
    |> ExAws.S3.put_object(
      leaderboard_filename,
      Poison.encode!(state)
    )
    |> ExAws.request()
  end

  def fetch_leaderboard() do
    Application.get_env(:snapeth, :bucket_name)
    |> ExAws.S3.get_object(leaderboard_filename)
    |> ExAws.request()
    |> case do
      {:ok, %{body: body}} ->
        Poison.decode!(body)

      {:error, {:http_error, 404, _}} ->
        create_leaderboard_file()

      error ->
        Logger.error("Error loading leaderboard! #{inspect(error)}")
    end
  end

  def clear_leaderboard() do
    persist_leaderboard(%{})

    %{}
  end

  def create_leaderboard_file() do
    persist_leaderboard(%{})

    %{}
  end
end
