defmodule Snapeth.SlackBot do
  use Slack

  @message_types [
      {~r/help/i, :help},
      {~r/^<@\w+>/, :snaps}
    ]

  # @delay

  def handle_connect(_, _state) do
    IO.puts("Slack bot connected to team Avvo")
    {:ok, %{}}
  end

  def handle_event(message = %{channel: "D" <> _, type: "message"}, slack, state) do
    {_, func} = Enum.find(@message_types,
                          {nil, :help},
                          fn {reg, _} -> String.match?(message.text, reg) end
                         )
                         IO.inspect func
    state = Kernel.apply(Snapeth.SlackBot, func, [message, slack, state])
    {:ok, state}
  end

  def handle_event(_message, _slack, state) do
    {:ok, state}
  end

  def help(message, slack, state) do
    send_message("Hi! To give snaps, start by tagging a team member and we'll instruct you from there. For example: @slackbot", message.channel, slack)
    state
  end

  def snaps(message, slack, state) do
    [_, user_id] = Regex.run(~r/^<@(\w+)>/, message.text)
    send_message("Oh snapeth, you got a snap from <@#{message.user}>!", user_id, slack)
    state = Map.update(state, user_id, 1, &(&1 + 1))
    snaps_leaderboard(slack, state)
    state
  end

  def snaps_leaderboard(slack, state) do
    leaderboard = state
    |> Enum.sort_by(&(elem(&1, 1)))
    |> Enum.reverse()
    |> Enum.map(fn {user, snap_count} ->
      "<@#{user}> received #{snap_count}!"
    end)
    |> Enum.join("\n")

    # see if we can't tag snapeth in here by handle
    send_message("Here is the daily leaderboard for snap recipients!\n#{leaderboard}", "#testing-stuff", slack)
  end

end
