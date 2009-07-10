require 'test/unit'
require 'rubygems'
require 'mocha'
require 'pruner'

class TestPruner < Test::Unit::TestCase
  
  NOW = Time.now
  
  # From RightAws::Ec2#describe_instances documentation.
  def volumes_array
    [{:aws_id => "vol-60957009"},
     {:aws_id => "vol-58957031"}]
  end
  
  # Generate twice hourly for yesterday
  # Should result in 24 deleted snapshots.
  def twice_hourly_yesterday
    yesterday = NOW - 1.day
    (1..48).map do |i|
      {:aws_progress   => "100%",
       :aws_status     => "completed",
       :aws_id         => "snap-yesterday-#{i}",
       :aws_volume_id  => "vol-60957009", 
       :aws_started_at => yesterday - i * 30.minutes}
    end
  end
  
  # Generate 2 times daily for last week.
  # Should result in 7 deleted snapshots.
  def twice_daily_last_week
    last_week = NOW - 1.week
    (1..14).map do |i|
      {:aws_progress   => "100%",
       :aws_status     => "completed",
       :aws_id         => "snap-last-week-#{i}",
       :aws_volume_id  => "vol-60957009",
       :aws_started_at => last_week - i * 12.hours}
    end
  end
  
  # Generate daily for last month.
  # Should result in 15 deleted snapshots
  def daily_last_month
    last_month = NOW - 1.month
    (1..30).map do |i|
      {:aws_progress   => "100%",
       :aws_status     => "completed",
       :aws_id         => "snap-last-month-#{i}",
       :aws_volume_id  => "vol-60957009",
       :aws_started_at => last_month - i * 1.day}
    end
  end
  
   # Generate 2 weekly for last quarter.
   # Should result in 6 deleted snapshots.
  def twice_weekly_last_quarter
    last_quarter = NOW - 3.months
    (1..12).map do |i|
      {:aws_progress   => "100%",
       :aws_status     => "completed",
       :aws_id         => "snap-last-quarter-#{i}",
       :aws_volume_id  => "vol-60957009",
       :aws_started_at => last_quarter - i * 3.days}
    end
  end
  
  # Generate weekly for last two years.
  # Should result in 16 deleted snapshots.
  def weekly_two_years_ago
    two_years_ago = NOW - 2.years
    (1..48).map do |i|
      {:aws_progress   => "100%",
       :aws_status     => "completed",
       :aws_id         => "snap-two-years-ago-#{i}",
       :aws_volume_id  => "vol-60957009",
       :aws_started_at => two_years_ago - i * 1.week}
    end
  end
  
  # Generate a set that we can prune from with known results.
  # RULES = [HOURLY_AFTER_A_DAY, DAILY_AFTER_A_WEEK, EVERY_OTHER_DAY_AFTER_A_MONTH, WEEKLY_AFTER_A_QUARTER, EVERY_THREE_WEEKS_AFTER_TWO_YEARS]
  def snapshots_array
    twice_hourly_yesterday + twice_daily_last_week + daily_last_month + twice_weekly_last_quarter + weekly_two_years_ago
  end
  
  def mock_aws
    @mock_ec2 = mock()
    RightAws::Ec2.stubs(:new).returns(@mock_ec2)
  end
  
  def new_pruner
    @pruner = Pruner.new({:volumes => [], :verbose => true, :live => true})
  end
  
  def setup
    mock_aws
    new_pruner
  end
  
  def teardown
    @pruner = nil
  end
  
  def test_no_window_overlap
    windows = [twice_hourly_yesterday, twice_daily_last_week, daily_last_month, twice_weekly_last_quarter, weekly_two_years_ago]
    windows.each do |window|
      assert_equal window & (windows.flatten - window), []
    end
  end
  
  def test_version
    assert_not_nil Pruner::VERSION
  end
  
  def test_ec2
    assert_not_nil @pruner.ec2
  end
  
  def test_volumes
    @mock_ec2.expects(:describe_volumes).returns(volumes_array).once
    assert_equal @pruner.volumes, volumes_array
  end
  
  def test_snapshots
    @mock_ec2.expects(:describe_volumes).returns(volumes_array).once
    @mock_ec2.expects(:describe_snapshots).returns(snapshots_array).once
    assert_equal @pruner.snapshots, snapshots_array
  end
  
  def test_apply_rule_HOURLY_AFTER_A_DAY
    @pruner.snapshots = twice_hourly_yesterday
    @pruner.apply_rule(Pruner::HOURLY_AFTER_A_DAY)
    assert_equal @pruner.old_snapshots.size, 24
  end
  
  def test_apply_rule_DAILY_AFTER_A_WEEK
    @pruner.snapshots = twice_daily_last_week
    @pruner.apply_rule(Pruner::DAILY_AFTER_A_WEEK)
    assert_equal @pruner.old_snapshots.size, 7
  end
  
  def test_apply_rule_EVERY_OTHER_DAY_AFTER_A_MONTH
    @pruner.snapshots = daily_last_month
    @pruner.apply_rule(Pruner::EVERY_OTHER_DAY_AFTER_A_MONTH)
    assert_equal @pruner.old_snapshots.size, 15
  end
  
  def test_apply_rule_WEEKLY_AFTER_A_QUARTER
    @pruner.snapshots = twice_weekly_last_quarter
    @pruner.apply_rule(Pruner::WEEKLY_AFTER_A_QUARTER)
    assert_equal @pruner.old_snapshots.size, 6
  end
  
  def test_apply_rule_EVERY_THREE_WEEKS_AFTER_TWO_YEARS
    @pruner.snapshots = weekly_two_years_ago
    @pruner.apply_rule(Pruner::EVERY_THREE_WEEKS_AFTER_TWO_YEARS)
    assert_equal @pruner.old_snapshots.size, 32
  end
  
  def test_apply_rules
    @pruner.snapshots = snapshots_array
    @pruner.apply_rules
    assert_equal @pruner.old_snapshots.size, 24 + 7 + 15 + 6 + 32
  end
  
  def test_remove_snapshots
    dead_snaps = 24 + 7 + 15 + 6 + 32
    @pruner.snapshots = snapshots_array
    @pruner.apply_rules
    @mock_ec2.expects(:delete_snapshot).times(dead_snaps)
    @pruner.remove_snapshots
  end
  
  def test_prune!
    dead_snaps = 24 + 7 + 15 + 6 + 32
    @mock_ec2.expects(:describe_volumes).returns(volumes_array).once
    @mock_ec2.expects(:describe_snapshots).returns(snapshots_array).once
    @mock_ec2.expects(:delete_snapshot).times(dead_snaps)
    @pruner.prune!
  end
end
