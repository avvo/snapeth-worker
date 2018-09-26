defmodule Snapeth.Application do
  use Application
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children =
      [
        {Snapeth, [0]},
        worker(Snapeth.Scheduler, [])
      ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
