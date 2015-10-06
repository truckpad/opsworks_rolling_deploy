require 'clamp'
module OpsworksRollingDeploy
  module Commands
    class DeployCommand < Clamp::Command
      option "--stack", "STACK_NAME", "the stack name", :required => true
      option "--app", "APP_NAME", "the application name", :required => true
    end
  end
end
