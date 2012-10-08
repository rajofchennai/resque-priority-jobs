require 'resque'
require 'resque-priority-jobs/queue'
require 'resque-priority-jobs/multi_queue'
require 'resque-priority-jobs/job'
require 'resque-priority-jobs/failure'
require 'resque-priority-jobs/failure/redis'

# Max priority is the highest priority similarly for min priority. These numbers are arbitrary
MIN_PRIORITY = 20
MAX_PRIORITY = 1

module Resque
  # Queues which need priority scheduling need to use this method instead of enqueue
  #FIXME: Known issue - If a use is already enqueued without priority and then we do a enqueue with priority we get an error of different datatype from redis.
  def enqueue_with_priority(klass, priority = MIN_PRIORITY, *args)
    queue = queue_from_class(klass)
    before_hooks = Plugin.before_enqueue_hooks(klass).collect do |hook|
      klass.send(hook, *args)
    end
    return nil if before_hooks.any? { |result| result == false }

    Job.create_with_priority(queue, klass, priority, *args)

    Plugin.after_enqueue_hooks(klass).each do |hook|
      klass.send(hook, *args)
    end

    return true
  end

  def push_with_priority(queue, priority, item)
    queue(queue).push_with_priority priority, item
  end

  class JobFetch
    def self.fetch_one_job(redis, queue)
      #lua script to get item with maximum priority
      get_and_rem = "local resp = redis.call('zrangebyscore', KEYS[1], '-inf', '+inf', 'LIMIT', '0', '1');
        if (resp[1] ~= nil) then
          local val = resp[# resp]
          redis.call('zrem', KEYS[1], val)
          return val
        else
          return false
        end"
      redis.eval get_and_rem, [queue]
    end
  end
end
