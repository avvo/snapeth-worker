defmodule Snapeth.SlackBot do
  use Slack

  @message_types [
      {~r/help/i, :help},
      {~r/^<@\w+>/, :snap},
      {~r/leaderboard/i, :leaderboard},
    ]

  def handle_connect(_, _state) do
    IO.puts("Slack bot connected to team Avvo")
    {:ok, %{}}
  end

  def handle_info(:display_leaderboard, slack, state) do
    snaps_leaderboard(slack, state, "#general")
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

  def snap(message, slack, state) do
    [_, user_id] = Regex.run(~r/^<@(\w+)>/, message.text)
    snap(message, slack, state, user_id)
  end

  def snap(message = %{user: user}, slack, state, user_id) when user_id == user do
    send_message("You can't snap yourself, but this is an opportunity to talk with your teammates about inclusive behaviors and being proactive with their snaps!", message.channel, slack)
    state
  end

  def snap(message, slack, state, user_id) do
    send_message("Oh snapeth, you got a snap from <@#{message.user}>!", user_id, slack)
    Map.update(state, user_id, 1, &(&1 + 1))
  end

  def leaderboard(message, slack, state) do
    snaps_leaderboard(slack, state, message.channel)
    state
  end

  def snaps_leaderboard(slack, state, channel) when map_size(state) == 0 do
    send_message("There have been no snaps today from <@#{slack.me.id}>.", channel, slack)
  end

  def snaps_leaderboard(slack, state, channel) do
    leaderboard = state
    |> Enum.sort_by(&(elem(&1, 1)))
    |> Enum.reverse()
    |> Enum.map(fn {user, snap_count} ->
      "<@#{user}> received #{snap_count}!"
    end)
    |> Enum.join("\n")

    send_message("Here is the daily leaderboard for <@#{slack.me.id}> recipients!\n#{leaderboard}", channel, slack)
  end

end
