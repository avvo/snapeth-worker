# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :snapeth, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:snapeth, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

config :logger,
  level: :debug

config :snapeth, Snapeth.Scheduler,
  jobs: [
    # Every Monday at 2:00
    {"0 14 * * MON", {Snapeth, :display_leaderboard, []}},
    # Every year
    {"0 0 1 1 *", {Snapeth, :clear_leaderboard, []}}
  ],
  timezone: "America/Los_Angeles"

config :snapeth,
  slack_bot_token: System.get_env("BOT_TOKEN") || "${BOT_TOKEN}",
  bucket_name: "snapeth",
  slack_channel: System.get_env("SLACK_CHANNEL") || "#general"

config :ex_aws,
  access_key_id: [{:system, "S3_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "S3_SECRET"}, :instance_role],
  region: "us-west-2"

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
