require 'test/unit'
require 'fakeweb'
require 'pruner'

class TestPruner < Test::Unit::TestCase
  
  def new_pruner
    @pruner = Pruner.new('../config.yml')
  end
  
  def stub_aws
    FakeWeb.register_uri(:any, 'https://ec2.amazonaws.com:443', :status => ['200', 'OK'])
  end
  
  def test_config_parsing
    new_pruner
    assert_equal @pruner.config[:access_key_id], 'access_key'
    assert_equal @pruner.config[:secret_access_key], 'secret_access_key'
  end
  
  def test_ec2
    stub_aws
    new_pruner
    assert_not_nil @pruner.ec2
  end
  
  def test_version
    assert_not_nil Pruner::VERSION
  end
end
