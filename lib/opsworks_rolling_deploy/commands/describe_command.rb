require 'clamp'
require 'opsworks_rolling_deploy/services/describe_service'

module OpsworksRollingDeploy
  module Commands
    class DescribeCommand < Clamp::Command
      option "--stack", "STACK_NAME", "the stack name", :required => false
      option "--app", "APP_NAME", "the application name", :required => false
      option "--layer", "LAYER_NAME", "the layer name", :required => false

      def execute
        OpsworksRollingDeploy::Services::DescribeService.new.describe(stack, app, layer)
      end
    end
  end
end
