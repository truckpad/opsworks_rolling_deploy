require 'clamp'
require 'opsworks_rolling_deploy/services/describe_service'

module OpsworksRollingDeploy
  module Commands
    class DescribeCommand < Clamp::Command
      option "--aws-id", "AWS_ACCESS_KEY_ID", "aws access key id", environment_variable: "AWS_ACCESS_KEY_ID"
      option "--aws-secret", "AWS_SECRET_ACCESS_KEY", "aws secret access key", environment_variable: "AWS_SECRET_ACCESS_KEY"

      option "--stack", "STACK_NAME", "the stack name", :required => false
      option "--app", "APP_NAME", "the application name", :required => false
      option "--layer", "LAYER_NAME", "the layer name", :required => false

      def execute
        OpsworksRollingDeploy.set_auth_default(aws_id, aws_secret) if aws_id
        OpsworksRollingDeploy::Services::DescribeService.new.describe(stack, app, layer)
      end
    end
  end
end
