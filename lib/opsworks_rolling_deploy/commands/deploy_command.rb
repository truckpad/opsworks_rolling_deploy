require 'clamp'
require 'opsworks_rolling_deploy/services/deploy_service'

module OpsworksRollingDeploy
  module Commands
    class DeployCommand < Clamp::Command
      option "--aws-id", "AWS_ACCESS_KEY_ID", "aws access key id", environment_variable: "AWS_ACCESS_KEY_ID"
      option "--aws-secret", "AWS_SECRET_ACCESS_KEY", "aws secret access key", environment_variable: "AWS_SECRET_ACCESS_KEY"

      option "--stack", "STACK_NAME", "the stack name", required: true
      option "--app", "APP_NAME", "the application name", required: true
      option "--pretend", :flag, "pretend execution"
      option "--exclude", "PATTERN" , "wildcard pattern to exclude hosts", multivalued: true 

      def execute
        OpsworksRollingDeploy.set_auth_default(aws_id, aws_secret) if aws_id
        Services::DeployService.new.deploy(stack, app, pretend?, exclude_list)
      end
    end
  end
end