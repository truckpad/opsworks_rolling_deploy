require 'opsworks_rolling_deploy/version'
require 'aws-sdk'
require 'logger'

# Module for rolling deploy management over opsworks
module OpsworksRollingDeploy
  def self.set_auth_default(aws_id, aws_secret)
    Aws.config.update(credentials: Aws::Credentials.new(aws_id, aws_secret) )
  end

  def self.set_verbose(verbose)
    Aws.config.update(logger: logger) if verbose
  end

  def self.logger
    @logger ||= begin
      Logger.new(STDOUT).tap do |l|
        $stdout.sync = true
        l.level = Logger::DEBUG
      end   
    end
  end
end