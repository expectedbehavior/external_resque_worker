# encoding: UTF-8
# Author:: Assaf Arkin  assaf@labnotes.org
#          Eric Hodel drbrain@segment7.net
# Copyright:: Copyright (c) 2005-2008 Assaf Arkin, Eric Hodel
# License:: MIT and/or Creative Commons Attribution-ShareAlike

require 'test/unit'
require 'rubygems'
require 'external_resque_worker'

ExternalResqueWorker.resque_work_command = 'bin/rake resque:work'
ExternalResqueWorker.kill_all_existing_workers

class TestExternalResqueWorkerJob
  def self.queue
    :test
  end
  def self.perform(*args)
  end
end

config =  YAML::load(File.open("#{File.dirname(__FILE__)}/redis.yml"))
$_redis = Redis.new(:host => config['host'], :port => config['port'])
Resque.redis = $_redis


class TestExternalResqueWorker < Test::Unit::TestCase

  def test_worker_pauses
    worker = ExternalResqueWorker.create_and_pause_shortly_thereafter
    assert_equal 0, Resque.size(:test)
    Resque.enqueue(TestExternalResqueWorkerJob)
    # assert there is one job in the queue
    assert_equal 1, Resque.size(:test)
    # unpause worker
    worker.unpause
    sleep 0.3
    # assert there are zero jobs in the queue
    assert_equal 0, Resque.size(:test)
  end

end

