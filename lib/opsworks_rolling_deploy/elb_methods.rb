module OpsworksRollingDeploy
  module ElbMethods
   ELB_STATUS_INSERVICE    = "InService"
   ELB_STATUS_OUTOFSERVICE = "OutOfService"

   def pools_of_instance(_stack, instance)
    ops_client.describe_elastic_load_balancers({
      layer_ids: instance.layer_ids,
      }).elastic_load_balancers
  end

  def remove_from_pools(stack, _app, instance)
      # XXX I did not figure out how to filter instances running the app 
      pools = pools_of_instance(stack, instance).each do |elb|
        info 'Instance', instance.hostname, instance.ec2_instance_id, "Remove from pool #{elb.elastic_load_balancer_name}"
        deregister_instances_from_load_balancer(elb, instance.ec2_instance_id) unless pretend?        
      end

      pools.each do |elb|
        wait_status(elb, instance.ec2_instance_id, ELB_STATUS_OUTOFSERVICE)
      end unless pretend?

      pools
    end

    def add_into_pools(_stack, instance, pools)
      pools.each do |elb|
        info 'Instance', instance.hostname, instance.ec2_instance_id, "Adding back to pool #{elb.elastic_load_balancer_name}"
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

    def get_elb_status(elb, instance_id)
      elb_client(elb.region).describe_instance_health({
        load_balancer_name: elb.elastic_load_balancer_name,
        instances: [ {instance_id: instance_id} ] 
        }).instance_states.last.state
    end

    def wait_status(elb, instance_id, status)
      $stdout.write get_elb_status(elb, instance_id)
      100.times do
        $stdout.write '.'
        instance_status = get_elb_status(elb, instance_id)
        if instance_status == status
          puts instance_status
          return true 
        end
        sleep 5
      end
      fail "Time out while waiting status"
    end
  end
end