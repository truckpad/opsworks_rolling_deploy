require 'opsworks_rolling_deploy/version'
require 'aws-sdk'

# Module for rolling deploy management over opsworks
module OpsworksRollingDeploy
  def self.set_auth_default(aws_id, aws_secret)
    Aws.config.update(credentials: Aws::Credentials.new(aws_id, aws_secret) )
  end
end
