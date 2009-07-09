require 'rubygems'
require 'yaml'
require 'right_aws'
require 'activesupport'

require 'pruner/version'

class Pruner
  attr_reader :config, :live, :verbose, :ec2, :volumes
  attr_accessor :old_snapshots
  
  HOURLY_AFTER_A_DAY =             {:after => Time.now - 1.week,
                                    :before => Time.now - 1.day,
                                    :interval =>1.hour}
  DAILY_AFTER_A_WEEK =             {:after => Time.now - 1.month,
                                    :before => Time.now - 1.week,
                                    :interval =>24.hour}
  TWICE_DAILY_AFTER_A_MONTH =      {:after => Time.now - 3.month,
                                    :before => Time.now - 1.month,
                                    :interval => 48.hour}
  WEEKLY_AFTER_A_QUARTER =         {:after => Time.now - 2.years,
                                    :before => Time.now - 3.month,
                                    :interval =>1.week}
  THRICE_WEEKLY_AFTER_TWO_YEARS =  {:after => Time.now - 10.years,
                                    :before => Time.now - 2.years,
                                    :interval =>3.week}
  
  RULES = [HOURLY_AFTER_A_DAY, DAILY_AFTER_A_WEEK, TWICE_DAILY_AFTER_A_MONTH, WEEKLY_AFTER_A_QUARTER, THRICE_WEEKLY_AFTER_TWO_YEARS]
  
  def initialize(options ={})
    @config =   YAML.load_file(File.dirname(__FILE__) + "/#{options[:config_file_path]}").symbolize_keys
    @live =     options[:live]
    @verbose =  options[:verbose]
  end
  
  def prune!
    volumes.each do |vol|
      
    end
    prune_snapshots!
  end
  
  def prune_snapshots!
    old_snapshots.each do |snap|
      puts "Removing: #{snap[:aws_id]}" if verbose
      ec2.delete_snapshot(snap[:aws_id]) if live
    end
  end
  
  def ec2
    @ec2 ||= RightAws::Ec2.new(config[:access_key_id], config[:secret_access_key])
  end
  
  def volumes
    @volumes ||= ec2.describe_volumes
    if verbose
      puts "#{@volumes.size} Volumes:"
      @volumes.each do |vol|
        puts "  #{vol[:aws_id]}"
      end
    end
  end
  
  def snapshots(volume)
    snaps = ec2.describe_snapshots(volume[:aws_id])
    puts "#{snaps.size} Snapshots for Volume #{volume[:aws_id]}}" if verbose
    snaps
  end
end