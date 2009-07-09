require 'rubygems'
require 'yaml'
require 'right_aws'
require 'activesupport'

require File.expand_path(File.dirname(__FILE__) + '/pruner/version')

class Pruner
  attr_reader :config, :live, :verbose, :ec2, :volumes
  attr_accessor :ec2, :volumes, :snapshots, :old_snapshots
  
  NOW = Time.now
  
  HOURLY_AFTER_A_DAY =                 {:after => NOW - 1.week,
                                        :before => NOW - 1.day,
                                        :interval => 1.hour}
  DAILY_AFTER_A_WEEK =                 {:after => NOW - 1.month,
                                        :before => NOW - 1.week,
                                        :interval => 24.hours}
  EVERY_OTHER_DAY_AFTER_A_MONTH =      {:after => NOW - 3.month,
                                        :before => NOW - 1.month,
                                        :interval => 48.hours}
  WEEKLY_AFTER_A_QUARTER =             {:after => NOW - 2.years,
                                        :before => NOW - 3.months,
                                        :interval => 1.week}
  EVERY_THREE_WEEKS_AFTER_TWO_YEARS =  {:after => NOW - 10.years,
                                        :before => NOW - 2.years,
                                        :interval => 3.weeks}
  
  RULES = [HOURLY_AFTER_A_DAY, DAILY_AFTER_A_WEEK, EVERY_OTHER_DAY_AFTER_A_MONTH, WEEKLY_AFTER_A_QUARTER, EVERY_THREE_WEEKS_AFTER_TWO_YEARS]
  
  def initialize(options ={})
    @config =         YAML.load_file(File.dirname(__FILE__) + "/#{options[:config_file_path]}").symbolize_keys
    @live =           options[:live]
    @verbose =        options[:verbose]
    @old_snapshots =  []
  end
  
  def prune!
    apply_rules
    remove_snapshots
  end
  
  def apply_rules
    RULES.each do |rule|
      apply_rule(rule)
    end
  end
  
  def apply_rule(rule)
    # Gather the snapshots that might fall in the rule's time window.
    vulnerable_snaps = snapshots.select { |snap| snap[:aws_started_at] > rule[:after] && snap[:aws_started_at] < rule[:before]}
    # Step across the rule's time window one interval at a time, keeping the last snapshot in that window.
    window_start = rule[:before] - rule[:interval]
    while window_start > rule[:after] do
      # Gather snaps in the window
      snaps_in_window = vulnerable_snaps.select { |snap| snap[:aws_started_at] > window_start && snap[:aws_started_at] < window_start + rule[:interval]}
      # The first one in the selection survives
      keeper = snaps_in_window.pop
      # Send the rest to die.
      @old_snapshots += snaps_in_window
      
      # Shrink the window
      window_start -= rule[:interval]
    end
    old_snapshots.uniq!
  end
  
  def remove_snapshots
    puts "Removing #{old_snapshots.size} Snapshots:" if verbose
    old_snapshots.each do |snap|
      puts "  #{snap[:aws_id]} - #{snap[:aws_started_at]}" if verbose
      ec2.delete_snapshot(snap[:aws_id]) if live
    end
    old_snapshots
  end
  
  def ec2
    @ec2 ||= RightAws::Ec2.new(config[:access_key_id], config[:secret_access_key])
  end
  
  def volumes
    @volumes ||= ec2.describe_volumes
  end
  
  def snapshots
    @snapshots ||= ec2.describe_snapshots.select do |snap|
      volumes.any? { |vol| vol[:aws_id] == snap[:aws_volume_id]}
    end
  end
end