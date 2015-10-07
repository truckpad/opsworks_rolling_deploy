require 'colorize'
require 'opsworks_rolling_deploy/clients'

module OpsworksRollingDeploy
	module Services
		class DeployService
      ELB_STATUS_INSERVICE    = "InService"
      ELB_STATUS_OUTOFSERVICE = "OutOfService"

			include OpsworksRollingDeploy::Clients 

      def deploy(stack_name, app_name, pretend = true, exclude_patterns = [])
        @pretend = pretend
        stack = get_stack(stack_name)
        app   = get_app(stack, app_name)

        instances = instances_to_deploy(stack, app, exclude_patterns)
        instances.each_with_index do |instance, idx|
          info instance.hostname, instance.ec2_instance_id
          pools = remove_from_pools(stack, app, instance)
          create_deployment(stack, app, instance, "#{idx+1}/#{instances.size}") 
          add_into_pools(stack, instance, pools)
        end
      end

      protected

      def pools_of_instance(stack, instance)
        ops_client.describe_elastic_load_balancers({
          layer_ids: instance.layer_ids,
          }).elastic_load_balancers
      end

      def warn(*strs)
        puts strs.join(' ').yellow
      end

      def info(*strs)
        puts strs.join(' ').blue
      end

      def match?(hostname, patterns)
        patterns.any?{|p| File.fnmatch?(p, hostname)}
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
            warn '  ', instance.hostname, instance.ec2_instance_id, "Skipping because it's excluded"
            next false
          end

          if instance.status != 'online'
            warn '  ', instance.hostname, instance.ec2_instance_id, "Skipping because it's not online"
            next false
          end
          true
        end
      end

      def remove_from_pools(stack, _app, instance)
        # XXX I did not figure out how to filter instances running the app 
        pools = pools_of_instance(stack, instance).each do |elb|
          info '  ', instance.hostname, instance.ec2_instance_id, "Remove from pool #{elb.elastic_load_balancer_name}"
          deregister_instances_from_load_balancer(elb, instance.ec2_instance_id) unless pretend?        
        end
        
        pools.each do |elb|
          wait_status(elb, instance.ec2_instance_id, ELB_STATUS_OUTOFSERVICE)
        end unless pretend?

        pools
      end

      def add_into_pools(stack, instance, pools)
        pools.each do |elb|
          info '  ', instance.hostname, instance.ec2_instance_id, "Adding back to pool #{elb.elastic_load_balancer_name}"
          register_instances_with_load_balancer(elb, instance.ec2_instance_id) unless pretend?        
        end

        pools.each do |elb|
          wait_status(elb, instance.ec2_instance_id, ELB_STATUS_INSERVICE)
        end unless pretend?
      end

      def deregister_instances_from_load_balancer(elb, instance_id)
        elb_client(elb.region).deregister_instances_from_load_balancer({
          load_balancer_name: elb.elastic_load_balancer_name,
          instances: [ # required
            { instance_id:  instance_id }
          ]
          })
      end

      def register_instances_with_load_balancer(elb, instance_id)
        elb_client(elb.region).register_instances_with_load_balancer({
          load_balancer_name: elb.elastic_load_balancer_name,
          instances: [ # required
            { instance_id:  instance_id }
          ]
          })
      end

      def create_deployment(stack, app, instance, comment)
        info '  ', instance.hostname, instance.ec2_instance_id, ["Deploying", comment].join(' ')
        return if pretend?
        deployment = ops_client.create_deployment(p( {
          stack_id: stack.stack_id,
          command: {name: 'deploy'}, 
          comment: 'Roll ' + comment,  
          custom_json: '{}',
          app_id: app.app_id,
          instance_ids: [instance.instance_id], 
          })) 
        wait_until_deployed(deployment.deployment_id)
      end

      def wait_until_deployed(deployment_id)
        deployment = nil
        loop do
          result = ops_client.describe_deployments(deployment_ids: [deployment_id])
          deployment = result[:deployments].first
          break unless deployment[:status] == "running"
          print "."
          sleep 5
        end
        deployment
      end

      def wait_status(elb, instance_id, status)
        100.times do
          p instance_status = get_elb_status(elb, instance_id)
          return true if instance_status ==  status
          sleep 1
        end
        fail "Time out while waiting status"
      end

      def pretend?
        @pretend && true
      end

      def get_elb_status(elb, instance_id)
        elb_client(elb.region).describe_instance_health({
          load_balancer_name: elb.elastic_load_balancer_name,
          instances: [ {instance_id: instance_id} ] 
          }).instance_states.last.state
      end
    end

  end
end
