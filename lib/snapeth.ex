defmodule Snapeth do
  use GenServer

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
    {:ok, pid} = Slack.Bot.start_link(Snapeth.SlackBot, [], Application.get_env(:snapeth, :slack_bot_token))
    {:ok, %{slack: pid}}
  end

  def handle_info(:work, state) do
    send(state.slack, :weekly_leaderboard)
    {:noreply, state}
  end

  def display_leaderboard() do
    send(SnapethMain, :work)
  end

end
