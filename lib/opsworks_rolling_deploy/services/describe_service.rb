require 'aws-sdk'
require 'colorize'
require 'opsworks_rolling_deploy/clients'

module OpsworksRollingDeploy
  module Services
    class DescribeService
      include OpsworksRollingDeploy::Clients

      def describe(stack_name, app_name, layer_name)
        ops_client.describe_stacks.stacks.each do |stack|
          next if stack_name and stack_name != stack.name

          puts "STACK = #{stack.name.green} #{stack.stack_id}"
          puts " APPS:"

          ops_client.describe_apps(stack_id: stack.stack_id).apps.each do |app|
            next if app_name and app_name != app.name
            puts "   APP: #{app.name.cyan} #{app.app_id} #{app.type}@#{app.app_source[:revision].to_s.magenta}"
          end

          puts " LAYERS:"
          ops_client.describe_layers(stack_id: stack.stack_id).layers.each do |layer|
            next if layer_name and layer_name != layer.name
            puts "   layer: #{layer.name.blue} #{layer.layer_id}"
            ops_client.describe_elastic_load_balancers(layer_ids:  [layer.layer_id]).elastic_load_balancers.each do |elb|
              puts "      ELB: #{elb.elastic_load_balancer_name.red} "

              if elb.ec2_instance_ids.any?
                describe_instance_health(elb)
              end
            end
          end
        end
        true
      end

      protected

      def describe_instance_health(elb)
        elb_client(elb.region).describe_instance_health({
          load_balancer_name: elb.elastic_load_balancer_name,
          instances: elb.ec2_instance_ids.map{ |id| {instance_id: id} }
        }).instance_states.each do |state|
          puts "      #{state.instance_id}: #{state.state}"
        end
      end
    end
  end
end
