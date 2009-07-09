require 'test/unit'
require 'rubygems'
require 'mocha'
require 'pruner'

class TestPruner < Test::Unit::TestCase
  
  NOW = Time.now
  
  # From RightAws::Ec2#describe_instances documentation.
  def volumes_array
    [{:aws_size              => 94,
      :aws_device            => "/dev/sdc",
      :aws_attachment_status => "attached",
      :zone                  => "merlot",
      :snapshot_id           => nil,
      :aws_attached_at       => NOW - 2.days,
      :aws_status            => "in-use",
      :aws_id                => "vol-60957009",
      :aws_created_at        => NOW - 3.days,
      :aws_instance_id       => "i-c014c0a9"},
     {:aws_size       => 1,
      :zone           => "merlot",
      :snapshot_id    => nil,
      :aws_status     => "available",
      :aws_id         => "vol-58957031",
      :aws_created_at => NOW - 3.days}]
  end
  
  # Generate a set that we can prune from with known results.
  # RULES = [HOURLY_AFTER_A_DAY, DAILY_AFTER_A_WEEK, EVERY_OTHER_DAY_AFTER_A_MONTH, WEEKLY_AFTER_A_QUARTER, EVERY_THREE_WEEKS_AFTER_TWO_YEARS]
  def snapshots_array
    snaps = []
    
    # Generate twice hourly for yesterday
    # Should result in 24 deleted snapshots.
    yesterday = NOW - 1.day
    snaps += (1..48).map do |i|
      {:aws_progress   => "100%",
       :aws_status     => "completed",
       :aws_id         => "snap-yesterday-#{i}",
       :aws_volume_id  => "vol-60957009",
       :aws_started_at => yesterday - i * 30.minutes}
    end
     
    # Generate 2 times daily for last week.
    # Should result in 7 deleted snapshots.
    last_week = NOW - 1.week
    snaps += (1..14).map do |i|
      {:aws_progress   => "100%",
       :aws_status     => "completed",
       :aws_id         => "snap-last-week-#{i}",
       :aws_volume_id  => "vol-60957009",
       :aws_started_at => last_week - i * 12.hours}
    end
    
    # Generate daily for last month.
    # Should result in 15 deleted snapshots.
    last_month = NOW - 1.month
    snaps += (1..31).map do |i|
      {:aws_progress   => "100%",
       :aws_status     => "completed",
       :aws_id         => "snap-last-month-#{i}",
       :aws_volume_id  => "vol-60957009",
       :aws_started_at => last_month - i * 1.day}
    end
    
    # Generate 2 weekly for last quarter.
    # Should result in 3 deleted snapshots.
    last_quarter = NOW - 3.months
    snaps += (1..6).map do |i|
      {:aws_progress   => "100%",
       :aws_status     => "completed",
       :aws_id         => "snap-last-quarter-#{i}",
       :aws_volume_id  => "vol-60957009",
       :aws_started_at => last_quarter - i * 3.days}
    end
    
    # Generate weekly for last two years.
    # Should result in 4 deleted snapshots.
    two_years_ago = NOW - 2.years
      snaps += (1..6).map do |i|
        {:aws_progress   => "100%",
         :aws_status     => "completed",
         :aws_id         => "snap-two-years-ago-#{i}",
         :aws_volume_id  => "vol-60957009",
         :aws_started_at => two_years_ago - i * 1.week}
    end
    
    snaps
  end
  
  def stub_aws
    ec2 = stub(:describe_volumes => volumes_array,
               :describe_snapshots => snapshots_array,
               :delete_snapshot => true)
    RightAws::Ec2.stubs(:new).returns(ec2)
  end
  
  def new_pruner
    @pruner = Pruner.new({:config_file_path => '../config.yml', :verbose => false, :live => true})
  end
  
  def setup
    stub_aws
    new_pruner
  end
  
  def test_version
    assert_not_nil Pruner::VERSION
  end
  
  def test_config_parsing
    assert_equal @pruner.config[:access_key_id], 'access_key'
    assert_equal @pruner.config[:secret_access_key], 'secret_access_key'
  end
  
  def test_ec2
    assert_not_nil @pruner.ec2
  end
  
  def test_volumes
    assert_equal @pruner.volumes, volumes_array
  end
  
  def test_find_volume_snapshots
    assert_equal @pruner.find_volume_snapshots(@pruner.volumes.first), snapshots_array
  end
  
  def test_find_all_snapshots
    @pruner.find_all_snapshots
    assert_equal @pruner.snapshots, snapshots_array + snapshots_array
  end
  
  def test_apply_rule_HOURLY_AFTER_A_DAY
    @pruner.snapshots = snapshots_array
    @pruner.apply_rule(Pruner::HOURLY_AFTER_A_DAY)
    assert_equal @pruner.old_snapshots.size, 24
  end
  
  def test_apply_rule_DAILY_AFTER_A_WEEK
    @pruner.snapshots = snapshots_array
    @pruner.apply_rule(Pruner::DAILY_AFTER_A_WEEK)
    assert_equal @pruner.old_snapshots.size, 7
  end
  
  def test_apply_rule_EVERY_OTHER_DAY_AFTER_A_MONTH
    @pruner.snapshots = snapshots_array
    @pruner.apply_rule(Pruner::EVERY_OTHER_DAY_AFTER_A_MONTH)
    assert_equal @pruner.old_snapshots.size, 15
  end
  
  def test_apply_rule_WEEKLY_AFTER_A_QUARTER
    @pruner.snapshots = snapshots_array
    @pruner.apply_rule(Pruner::WEEKLY_AFTER_A_QUARTER)
    assert_equal @pruner.old_snapshots.size, 3
  end
  
  def test_apply_rule_EVERY_THREE_WEEKS_AFTER_TWO_YEARS
    @pruner.snapshots = snapshots_array
    @pruner.apply_rule(Pruner::EVERY_THREE_WEEKS_AFTER_TWO_YEARS)
    assert_equal @pruner.old_snapshots.size, 4
  end
  
  def test_apply_rules
    @pruner.snapshots = snapshots_array
    @pruner.apply_rules
    assert_equal @pruner.old_snapshots.size, 24 + 7 + 15 + 3 + 4
  end
  
  def test_prune!
    @pruner.ec2.expects(:delete_snapshot)
    @pruner.prune!
  end
end
