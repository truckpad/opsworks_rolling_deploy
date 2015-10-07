require 'clamp'
require 'opsworks_rolling_deploy/services/deploy_service'

module OpsworksRollingDeploy
  module Commands
    class DeployCommand < Clamp::Command
      option "--stack", "STACK_NAME", "the stack name", required: true
      option "--app", "APP_NAME", "the application name", required: true
      option "--pretend", :flag, "pretend execution"
      option "--exclude", "PATTERN" , "wildcard pattern to exclude hosts", multivalued: true 
      def execute
        Services::DeployService.new.deploy(stack, app, pretend?, exclude_list)
      end
    end
  end
end