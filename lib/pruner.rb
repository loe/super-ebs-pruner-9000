require 'right_aws'
require 'activesupport'

require File.expand_path(File.dirname(__FILE__) + '/pruner/version')
require File.expand_path(File.dirname(__FILE__) + '/pruner/silence_ssl_warning')

class Pruner
  attr_reader :options
  attr_accessor :ec2, :volumes, :all_snapshots, :old_snapshots
  
  NOW = Time.now
  
  HOURLY_AFTER_A_DAY =                 {:after => NOW - 1.week,
                                        :before => NOW - 1.day,
                                        :interval => 1.hour,
                                        :name => 'Hourly After A Day'}
  DAILY_AFTER_A_WEEK =                 {:after => NOW - 1.month,
                                        :before => NOW - 1.week,
                                        :interval => 24.hours,
                                        :name => 'Daily After A Week'}
  EVERY_OTHER_DAY_AFTER_A_MONTH =      {:after => NOW - 3.month,
                                        :before => NOW - 1.month,
                                        :interval => 48.hours,
                                        :name => 'Every Other Day After A Month'}
  WEEKLY_AFTER_A_QUARTER =             {:after => NOW - 2.years,
                                        :before => NOW - 3.months,
                                        :interval => 1.week,
                                        :name => 'Weekly After A Quarter'}
  EVERY_THREE_WEEKS_AFTER_TWO_YEARS =  {:after => NOW - 10.years,
                                        :before => NOW - 2.years,
                                        :interval => 3.weeks,
                                        :name => 'Every Three Weeks After Two Years'}
  
  RULES = [HOURLY_AFTER_A_DAY, DAILY_AFTER_A_WEEK, EVERY_OTHER_DAY_AFTER_A_MONTH, WEEKLY_AFTER_A_QUARTER, EVERY_THREE_WEEKS_AFTER_TWO_YEARS]
  
  def initialize(options ={})
    @options =        options
    @old_snapshots =  []
  end
  
  def prune!
    apply_rules
    remove_snapshots
  end
  
  def apply_rules
    RULES.each do |rule|
      cached_size = old_snapshots.size if options[:verbose]
      apply_rule(rule)
      puts "#{rule[:name]}:  #{old_snapshots.size - cached_size}" if options[:verbose]
    end
  end
  
  def apply_rule(rule)
    volumes.each do |volume|
      
      # Gather the snapshots that might fall in the rule's time window.
      vulnerable_snaps = snapshots(volume).select { |snap| snap[:aws_started_at] > rule[:after] && snap[:aws_started_at] < rule[:before]}
      
      # Step across the rule's time window one interval at a time, keeping the last snapshot in that window.
      window_start = rule[:before] - rule[:interval]
      while window_start > rule[:after] do
        # Gather snaps in the window
        snaps_in_window = vulnerable_snaps.select { |snap| snap[:aws_started_at] >= window_start && snap[:aws_started_at] < window_start + rule[:interval]}
        # The first one in the selection survives
        keeper = snaps_in_window.pop
        # Send the rest to die.
        @old_snapshots += snaps_in_window
        # Shrink the window
        window_start -= rule[:interval]
      end
    end
    
    old_snapshots
  end
  
  def remove_snapshots
    puts "Removing #{old_snapshots.size} Snapshots:" if options[:verbose]
    old_snapshots.each do |snap|
      puts "  #{snap[:aws_id]} - #{snap[:aws_started_at]} (#{snap[:aws_volume_id]})" if options[:verbose]
      ec2.delete_snapshot(snap[:aws_id]) if options[:live]
    end
    
    old_snapshots
  end
  
  def ec2
    @ec2 ||= RightAws::Ec2.new(options[:aws_id], options[:aws_key])
  end
  
  def volumes
    @volumes ||= options[:volumes].empty? ? ec2.describe_volumes.map {|vol| vol[:aws_id] } : options[:volumes]
  end
  
  def all_snapshots
    @all_snapshots ||= ec2.describe_snapshots
  end
  
  def snapshots(volume)
    all_snapshots.select { |snap| volume == snap[:aws_volume_id] }
  end
end