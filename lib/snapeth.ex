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
    GenServer.start_link(__MODULE__, team_id)
  end

  def init(_team_id) do
    schedule_work()
    {:ok, pid} = Slack.Bot.start_link(Snapeth.SlackBot, [], Application.get_env(:snapeth, :slack_bot_token))
    {:ok, %{slack: pid}}
  end

  def handle_info(:work, state) do
    send(state.slack, :display_leaderboard)
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 5000)
    # fix this to not be 10 secs
  end

end
