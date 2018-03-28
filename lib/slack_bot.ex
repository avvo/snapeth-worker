defmodule Snapeth.SlackBot do
  use Slack

  @message_types [
      {~r/help/i, :help},
      {~r/^<@\w+>/, :snaps}
    ]

  def handle_connect(_, state) do
    IO.puts("Slack bot connected to team Avvo")
    {:ok, state}
  end

  def handle_event(message = %{channel: "D" <> _, type: "message"}, slack, state) do
    {_, func} = Enum.find(@message_types,
                          {nil, :help},
                          fn {reg, _} -> String.match?(message.text, reg) end
                         )
                         IO.inspect func
    Kernel.apply(Snapeth.SlackBot, func, [message, slack, state])
    {:ok, state}
  end

  def handle_event(_message, _slack, state) do
    {:ok, state}
  end

  def help(message, slack, state) do
    send_message("Hi! To give snaps, start by tagging a team member and we'll instruct you from there. For example: @slackbot", message.channel, slack)
  end

  def snaps(message, slack, state) do
    IO.puts("I got to snaps method")
    [_, user_id] = Regex.run(~r/^<@(\w+)>/, message.text)
    IO.puts user_id
    send_message("Oh snapeth, you got a snap!", user_id, slack) |> IO.inspect
  end

end
