require 'clamp'
require 'opsworks_rolling_deploy/commands/describe'
require 'opsworks_rolling_deploy/commands/deploy'

module OpsworkdsRollingDeploy
  class Cli < Clamp::Command
    subcommand ['describe'], 'Describe current OpsWorks Structure', Commands::DescribeCommand
    subcommand %w(deploy roll), 'Perform a rolling deploy', Commands::DeployCommand
  end
end
