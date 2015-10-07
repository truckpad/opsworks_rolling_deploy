require 'colorize'
require 'opsworks_rolling_deploy/clients'
require 'opsworks_rolling_deploy/output_methods'
require 'opsworks_rolling_deploy/elb_methods'

module OpsworksRollingDeploy
  module Services
    class DeployService

      include OpsworksRollingDeploy::Clients 
      include OpsworksRollingDeploy::OutputMethods
      include OpsworksRollingDeploy::ElbMethods

      def deploy(stack_name, app_name, pretend = true, exclude_patterns = [])
        @pretend = pretend
        stack = get_stack(stack_name)
        app   = get_app(stack, app_name)

        instances = instances_to_deploy(stack, app, exclude_patterns)
        instances.shuffle!
        instances.each_with_index do |instance, idx|
          info instance.hostname, instance.ec2_instance_id
          pools = remove_from_pools(stack, app, instance)
          create_deployment(stack, app, instance, "#{idx+1}/#{instances.size}") 
          add_into_pools(stack, instance, pools)
        end
      end

      protected

      def match?(hostname, patterns)
        patterns.any?{|pattern| File.fnmatch?(pattern, hostname)}
      end

      def get_stack(stack_name)
        get_stacks.detect{|s| s.name == stack_name }
      end

      def get_stacks
        @stacks ||= ops_client.describe_stacks().stacks
      end

      def get_app(stack, app_name)
        get_apps(stack).detect{|a| a.name == app_name }
      end

      def get_apps(stack)
        @apps ||= {}
        @apps[stack.stack_id] ||= ops_client.describe_apps(stack_id: stack.stack_id).apps
      end

      def instances_to_deploy(stack, _app, exclude_patterns)
        # XXX I did not figure out how to filter instances running the app 
        ops_client.describe_instances(stack_id: stack.stack_id).instances.select do |instance|
          if match?(instance.hostname, exclude_patterns)
            warn 'Instance', instance.hostname, instance.ec2_instance_id, "Skipping because it's excluded"
            next false
          end

          if instance.status != 'online'
            warn 'Instance', instance.hostname, instance.ec2_instance_id, "Skipping because it's not online"
            next false
          end
          true
        end
      end

      def create_deployment(stack, app, instance, comment)
        info 'Instance', instance.hostname, instance.ec2_instance_id, "Deploying", comment
        return if pretend?
        deployment = ops_client.create_deployment({
          stack_id: stack.stack_id,
          command: {name: 'deploy'}, 
          comment: 'Roll ' + comment,  
          custom_json: '{}',
          app_id: app.app_id,
          instance_ids: [instance.instance_id], 
          }) 
        wait_until_deployed(deployment.deployment_id)
      end

      def wait_until_deployed(deployment_id)
        deployment = nil
        
        status = ops_client.describe_deployments(deployment_ids: [deployment_id]).deployments.first.status
        $stdout.write status

        loop do
          sleep 5

          $stdout.write "."
          status = ops_client.describe_deployments(deployment_ids: [deployment_id]).deployments.first.status

          if status != "running"
            puts status 
            fail "Deploy status #{status}}" if status != 'successful'
            return
          end
        end
      end

      def pretend?
        @pretend && true
      end
    end
  end
end
