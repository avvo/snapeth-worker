defmodule Snapeth.SlackBot do
  use Slack
  require Logger
  alias Snapeth.Storage

  @message_types [
    {~r/help/i, :help},
    {~r/^<@\w+>/, :snap},
    {~r/leaderboard/i, :leaderboard}
  ]

  @snapeth_app_id "UD0V0C3Q8"
  @snapeth_bot_id "UD1J0C43D"

  ##########
  # CLIENT #
  ##########
  def help(message, slack, state) do
    help_message = """
    Have you seen someone demonstrate a positive and inclusive behavior at work?
    Tag that teammate here to give them an appreciative snap!

    For example:

    >@slackbot
    _or_
    >@slackbot I appreciate you always considering accessibility when developing features.
    """

    send_message(help_message, message.channel, slack)

    state
  end

  def snap(message, slack, state) do
    splitted_string = String.split(message.text, " ")

    [user_id | rest] = splitted_string
    [last_word | reversed_message] = Enum.reverse(rest)
    channel = channel_name(last_word)

    message_body =
      case channel do
        "" -> rest
        _ -> Enum.reverse(reversed_message)
      end
      |> Enum.join(" ")

    message = Map.put(message, :text, message_body)
    snap(message, slack, state, user_id, channel)
  end

  defp channel_name(":public:") do
    "#snapeth-general"
  end

  defp channel_name("<#"<>_channel_name = ch) do
    [_, ch_name] = String.split(ch, "|")
    ">"<>new_ch_name = String.reverse(ch_name)
    "#"<>String.reverse(new_ch_name)
  end

  defp channel_name(_word) do
    ""
  end

  def snap(message = %{user: user}, slack, state, user_id, _channel) when user_id == user do
    message_text = """
    You can't snap yourself, but this is an opportunity
    to talk with your teammates about inclusive behaviors
    and being proactive with their snaps!
    """

    send_message(message_text, message.channel, slack)

    state
  end

  def snap(message, slack, state, user_id, _channel)
      when user_id in [@snapeth_app_id, @snapeth_bot_id] do
    "Snapeth appreciates the sentiment, but would prefer you snap your teammates instead!"
    |> send_message(message.channel, slack)

    state
  end

  # private (channel is empty)
  def snap(message, slack, state, user_id, "") do
    snap_reason = strip_mention(message.text)

    "Oh snapeth, you got a snap from <@#{message.user}>!"
    |> add_snap_reason(snap_reason)
    |> send_message(user_id, slack)

    ":party-corgi: Your snap was delivered!"
    |> send_message(message.channel, slack)

    Map.update(state, user_id, 1, &(&1 + 1))
  end

  # :public (#general channel)
  def snap(message, slack, state, user_id, ":public:") do
    snap(message, slack, state, user_id, "#snapeth-general")
  end

  def snap(message, slack, state, user_id, channel) do
    snap_reason = strip_mention(message.text)

    "Oh snapeth, #{user_id} got a snap!"
    |> add_snap_reason(snap_reason)
    |> send_message(channel, slack)

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
    leaderboard =
      state
      |> Enum.sort_by(fn {_user, count} -> count end, &>=/2)
      |> Enum.reduce(fn {user, snap_count}, board ->
        "#{board} \n <@#{user}> received #{snap_count}!"
      end)

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

  defp strip_mention(text) do
    String.replace(text, ~r/#[\w_-]+|:public:|<\w+>/, "")
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
    {_, func} =
      Enum.find(
        @message_types,
        {nil, :help},
        fn {reg, _} -> String.match?(message.text, reg) end
      )

    state = Kernel.apply(Snapeth.SlackBot, func, [message, slack, state])

    send(self(), :persist_leaderboard)
    Logger.info("Persisted leaderboard")

    {:ok, state}
  end

  def handle_event(_message, _slack, state) do
    {:ok, state}
  end
end
