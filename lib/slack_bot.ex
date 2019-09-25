defmodule Snapeth.SlackBot do
  use Slack
  require Logger
  alias Snapeth.Storage

  @message_types [
      {~r/help/i, :help},
      {~r/^<@\w+>/, :snap},
      {~r/leaderboard/i, :leaderboard},
    ]

  @snapeth_app_id "UD0V0C3Q8"
  @snapeth_bot_id "UD1J0C43D"

  ##########
  # CLIENT #
  ##########
  def help(message, slack, state) do
    """
    Have you seen someone demonstrate a positive and inclusive behavior at work?
    Tag that teammate here to give them an appreciative snap!

    For example:

    >@slackbot
    _or_
    >@slackbot I appreciate you always considering accessibility when developing features.
    """
    |> send_message(message.channel, slack)
    state
  end

  def snap(message, slack, state) do
    [_, user_id] = Regex.run(~r/^<@(\w+)>/, message.text)
    snap(message, slack, state, user_id)
  end

  def snap(message = %{user: user}, slack, state, user_id) when user_id == user do
    "You can't snap yourself, but this is an opportunity " <>
    "to talk with your teammates about inclusive behaviors " <>
    "and being proactive with their snaps!"
    |> send_message(message.channel, slack)

    state
  end

  def snap(message = %{user: user}, slack, state, user_id) when user_id == @snapeth_app_id or user_id == @snapeth_bot_id do
    "Snapeth appreciates the sentiment, but would prefer you snap your teammates instead!"
    |> send_message(message.channel, slack)

    state
  end

  def snap(message, slack, state, user_id) do
    snap_reason = strip_mention(message.text, user_id)

    "Oh snapeth, you got a snap from <@#{message.user}>!"
    |> add_snap_reason(snap_reason)
    |> send_message(user_id, slack)

    ":party-corgi: Your snap was delivered!"
    |> send_message(message.channel, slack)

    Map.update(state, user_id, 1, &(&1 + 1))
  end

  def leaderboard(message, slack, state) do
    display_leaderboard(slack, state, message.channel)
    state
  end

  def display_leaderboard(slack, state, channel) when map_size(state) == 0 do
    send_message("There have been no snaps this week from <@#{slack.me.id}>.", channel, slack)
  end

  def display_leaderboard(slack, state, channel) do
    leaderboard = state
    |> Enum.sort_by(&(elem(&1, 1)))
    |> Enum.reverse()
    |> Enum.map(fn {user, snap_count} ->
      "<@#{user}> received #{snap_count}!"
    end)
    |> Enum.join("\n")

    """
    Here is the weekly leaderboard for <@#{slack.me.id}> recipients!
    #{leaderboard}

    You can give snaps via the Snapeth app!
    This leaderboard resets every Monday at 2:01PM PST.
    """
    |> send_message(channel, slack)
  end

  defp add_snap_reason(message, nil), do: message

  defp add_snap_reason(message, reason) do
    message <> "\n_#{reason}_"
  end

  defp strip_mention(text, mentioned_user_id) do
    at_mention_length = String.length("<@#{mentioned_user_id}> ")
    case String.trim(text) do
      <<_at_mention::binary-size(at_mention_length), snap_reason::binary>> ->
        snap_reason
      _ ->
        nil
    end
  end

  ##########
  # SERVER #
  ##########
  def handle_connect(_, state) do
    IO.puts("Slack bot connected to team Avvo")

    case state do
      [] ->
        {:ok, %{}}

      _ ->
        {:ok, state}
    end
  end

  def handle_info(:barf_state, _slack, state) do
    IO.inspect(state)
    {:ok, state}
  end

  def handle_info({:load_user, user_id, score}, _slack, []) do
    {:ok, Map.put(%{}, user_id, score)}
  end

  def handle_info({:load_user, user_id, score}, _slack, state) do
    {:ok, Map.put(state, user_id, score)}
  end

  def handle_info(:weekly_leaderboard, slack, state) do
    display_leaderboard(slack, state, "#snapeth-general")

    {:ok, state}
  end

  def handle_info(:persist_leaderboard, _slack, state) do
    Storage.persist_leaderboard(state)
    {:ok, state}
  end

  def handle_info(:clear_leaderboard, _slack, _state) do
    {:ok, %{}}
  end

  def handle_event(%{user: user}, %{me: %{id: id}}, state) when user == id do
    {:ok, state}
  end

  def handle_event(message = %{channel: "D" <> _, type: "message"}, slack, state) do
    {_, func} = Enum.find(@message_types,
                          {nil, :help},
                          fn {reg, _} -> String.match?(message.text, reg) end
                         )
                         IO.inspect func
    state = Kernel.apply(Snapeth.SlackBot, func, [message, slack, state])

    send(self(), :persist_leaderboard)
    Logger.info("Persisted leaderboard")

    {:ok, state}
  end

  def handle_event(_message, _slack, state) do
    {:ok, state}
  end

end
