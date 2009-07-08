require 'test/unit'
require 'rubygems'
require 'mocha'
require 'pruner'

class TestPruner < Test::Unit::TestCase
  
  # From RightAws::Ec2#describe_instances documentation.
  def volumes_array
    [{:aws_size              => 94,
      :aws_device            => "/dev/sdc",
      :aws_attachment_status => "attached",
      :zone                  => "merlot",
      :snapshot_id           => nil,
      :aws_attached_at       => "Wed Jun 18 08:19:28 UTC 2008",
      :aws_status            => "in-use",
      :aws_id                => "vol-60957009",
      :aws_created_at        => "Wed Jun 18 08:19:20s UTC 2008",
      :aws_instance_id       => "i-c014c0a9"},
     {:aws_size       => 1,
      :zone           => "merlot",
      :snapshot_id    => nil,
      :aws_status     => "available",
      :aws_id         => "vol-58957031",
      :aws_created_at => "Wed Jun 18 08:19:21 UTC 2008"}]
  end
  
  def snapshots_array
    [{:aws_progress   => "100%",
      :aws_status     => "completed",
      :aws_id         => "snap-72a5401b",
      :aws_volume_id  => "vol-5582673c",
      :aws_started_at => "2008-02-23T02:50:48.000Z"},
     {:aws_progress   => "100%",
      :aws_status     => "completed",
      :aws_id         => "snap-75a5401c",
      :aws_volume_id  => "vol-5582673c",
      :aws_started_at => "2008-02-23T16:23:19.000Z"}]
  end
  
  def stub_aws
    ec2 = stub(:describe_volumes => volumes_array,
               :describe_snapshots => snapshots_array,
               :delete_snapshot => true)
    RightAws::Ec2.stubs(:new).returns(ec2)
  end
  
  def new_pruner
    @pruner = Pruner.new('../config.yml')
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
  
  def test_snapshots
    assert_equal @pruner.snapshots(@pruner.volumes.first), snapshots_array
  end
end
