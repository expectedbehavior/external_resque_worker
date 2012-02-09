require 'resque'
class ExternalResqueWorker
  DEFAULT_STARTUP_TIMEOUT = 1.minute

  attr_accessor :pid, :startup_timeout
  private_class_method :new

  # It's very difficult to ensure a worker is paused before it works any jobs if jobs exist before the worker is created. Run this before actually having jobs enqueued if you don't want them to run at first.
  def self.create_and_pause_shortly_thereafter(queues_to_watch = '*')
    new(queues_to_watch)
  end

  def initialize(queues_to_watch = '*')
    @queues = [queues_to_watch].flatten
    start
  end
  
  def start
    raise "PEDANTICALLY CODED TO ONLY WORK IN TEST ENV" unless Rails.env.test?
    if self.pid = fork
      Process.detach(pid)
      # Since pausing is done by signal USR2, there will be a time between when the worker starts and when we can pause it.
      wait_for_worker_to_start
      pause
    else
      STDOUT.reopen(File.open("#{Rails.root}/log/external_resque_worker.log", "a+")) # stops it from giving us the extra test output
      start_child
    end
  end

  def self.kill_all_existing_workers
    while Resque::Worker.all.size > 0
      Resque::Worker.all.each do |w|
        Process.kill("TERM", w.pid) rescue nil
        w.prune_dead_workers
      end
    end
  end

  def process_all
    unpause
    sleep 1 until done?
    pause
  end

  def pause(pid = self.pid)
    Process.kill("USR2", pid)
  end

  def unpause
    Process.kill("CONT", pid)
  end

  def queues
    @queues.map {|queue| queue == "*" ? Resque.queues.sort : queue }.flatten.uniq
  end

  private

  def done?
    our_queues_empty = queues.all? do |queue|
      Resque.peek(queue).blank?
    end

    our_workers_done = (Resque::Worker.working.map{ |worker| worker.job['queue'] }.flatten & queues).empty?

    our_queues_empty and our_workers_done
  end

  def start_parent
    at_exit do
      Process.kill("KILL", pid) if pid
    end
  end

  def start_child
    # Array form of exec() is required here, otherwise the worker is not a direct
    # child process of test.
    # If it's not the direct child process then the PID returned from fork() is
    # wrong, which means we can't communicate with the worker.
    exec('bundle', 'exec', 'rake', "--silent", 'environment', 'resque:work', "QUEUE=#{@queues.join(',')}", "INTERVAL=0.25", "RAILS_ENV=test", "VVERBOSE=1")
  end

  def wait_for_worker_to_start
    self.startup_timeout ||= DEFAULT_STARTUP_TIMEOUT
    start = Time.now.to_i
    while (Time.now.to_i - start) < startup_timeout
      return if worker_started?
      sleep 1
    end

    raise "Timeout while waiting for the worker to start. Waited #{startup_timeout} seconds."
  end

  def worker_started?
    Resque.workers.any? { |worker| worker.pid == self.pid }
  end
end
