require 'rubygems'
require 'yaml'
require 'right_aws'

require 'pruner/version'

class Pruner
  attr_reader :config, :ec2
  
  def initialize(config_file_path)
    @config = YAML.load_file(File.dirname(__FILE__) + "/#{config_file_path}").symbolize_keys
  end
  
  def ec2
    @ec2 ||= RightAws::Ec2.new(config[:access_key_id], config[:secret_access_key])
  end
end