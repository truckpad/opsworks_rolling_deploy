# AWS clients utility
module OpsworksRollingDeploy

	module Clients
		def ops_client
			@ops_client ||= Aws::OpsWorks::Client.new(region: 'us-east-1')
		end
		def elb_client(region = 'us-east-1') 
			@elb_client ||={}
			@elb_client[region] ||= Aws::ElasticLoadBalancing::Client.new(region: region)
		end
	end
end
