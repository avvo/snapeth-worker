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
    # schedule_work()
    {:ok, pid} = Slack.Bot.start_link(Snapeth.SlackBot, [], Application.get_env(:snapeth, :slack_bot_token))
    {:ok, %{slack: pid}}
  end

  def handle_info(:work, state) do
    send(state.slack, :display_leaderboard)
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    next_wednesday_at_1400 = Timex.now
    |> Map.put(:hours, 21)
    |> Timex.shift(hours: 24)
    |> shift_until_wednesday()

    delay = DateTime.diff(next_wednesday_at_1400, Timex.now)
    # worst case, we'll end up waiting 8 days

    Process.send_after(self(), :work, delay)
  end

  defp shift_until_wednesday(time) do
    if Date.day_of_week(time) == 3 do
      time
    else
      shift_until_wednesday(Timex.shift(time, hours: 24))
    end

  end

end
