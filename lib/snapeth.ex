defmodule Snapeth do
  use GenServer
  require Logger

  alias Snapeth.Storage

  ##########
  # CLIENT #
  ##########
  def display_leaderboard() do
    send(SnapethMain, :work)
  end

  def clear_leaderboard() do
    Storage.clear_leaderboard()
    send(SnapethMain, :clear_leaderboard)
  end


  ##########
  # SERVER #
  ##########
  def child_spec(team_id) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [team_id]},
      type: :worker
    }
  end

  def start_link(team_id) do
    GenServer.start_link(__MODULE__, team_id, name: SnapethMain)
  end

  def init(_team_id) do
    Logger.info("Running with token #{inspect Application.get_env(:snapeth, :slack_bot_token)}")

    {:ok, pid} = Slack.Bot.start_link(
      Snapeth.SlackBot,
      [],
      Application.get_env(:snapeth, :slack_bot_token)
    )

    Logger.info("Loading leaderboard...")
    Storage.fetch_leaderboard()
    |> load_leaderboard(pid)
    |> (fn users_loaded ->
      Logger.info("Loaded standings for #{inspect users_loaded} users")
    end).()

    {:ok, %{slack: pid}}
  end

  def handle_info(:work, state) do
    send(state.slack, :weekly_leaderboard)
    {:noreply, state}
  end

  def handle_info(:clear_leaderboard, state) do
    send(state.slack, :clear_leaderboard)
    {:noreply, state}
  end

  def handle_info(:barf_state, state) do
    send(state.slack, :barf_state)
    {:noreply, state}
  end

  ###########
  # HELPERS #
  ###########
  defp load_leaderboard(users, slack_bot_pid) do
    users
    |> Enum.each(fn {user_id, score} ->
      send(slack_bot_pid, {:load_user, user_id, score})
    end)

    Map.keys(users) |> length
  end

end
