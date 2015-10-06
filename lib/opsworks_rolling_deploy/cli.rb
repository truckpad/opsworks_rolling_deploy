require 'clamp'
require 'opsworks_rolling_deploy/commands/describe'
require 'opsworks_rolling_deploy/commands/deploy'

module OpsworksRollingDeploy
  class Cli < Clamp::Command
    subcommand ['describe'], 'Describe current OpsWorks Structure', OpsworksRollingDeploy::Commands::DescribeCommand
    subcommand %w(deploy roll), 'Perform a rolling deploy', OpsworksRollingDeploy::Commands::DeployCommand
  end
end
