require 'clamp'
require 'opsworks_rolling_deploy/services/deploy_service'
require 'json'
module OpsworksRollingDeploy
  module Commands
    class DeployCommand < Clamp::Command
      option "--aws-id", "AWS_ACCESS_KEY_ID", "aws access key id", environment_variable: "AWS_ACCESS_KEY_ID"
      option "--aws-secret", "AWS_SECRET_ACCESS_KEY", "aws secret access key", environment_variable: "AWS_SECRET_ACCESS_KEY"

      option "--stack", "STACK_NAME", "the stack name", required: true
      option "--app", "APP_NAME", "the application name", required: true
      option "--layer", "LAYER_NAME", "the layer name", required: false

      option "--command", "COMMAND", "the command to be executed by opsworks", default: 'deploy'
      option "--command-args", "COMMAND_ARGS", "the args to the command to be executed by opsworks as JSON (e.g. '{\"migrate\":[\"true\"]}'", default: '{}'
      option "--custom-json", "CUSTOM_JSON", " A string that contains user-defined, custom JSON. It is used to override the corresponding default stack configuration JSON values (e.g. '{\"key1\": \"value1\", \"key2\": \"value2\",...}'", default: '{}'

      option "--pretend", :flag, "pretend execution"
      option "--verbose", :flag, "display aws commands"
      option "--exclude", "PATTERN" , "wildcard pattern to exclude hosts", multivalued: true

      def execute
        OpsworksRollingDeploy.set_verbose(verbose?)
        OpsworksRollingDeploy.set_auth_default(aws_id, aws_secret) if aws_id
        Services::DeployService.new.deploy(stack, layer, app, command, JSON.parse(command_args), custom_json, pretend?, exclude_list)
      end
    end
  end
end
