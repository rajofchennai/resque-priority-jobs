module Resque
  class MultiQueue
    # worker polling aliased
    #TODO: Known Performance issue to ensure that same job is not done twice. Can be fixed after redis-2.6 is released
    def poll_with_priority timeout
      normal_queue_names = @queues.map {|queue| queue.redis_name  unless queue.is_a_priority_queue? }
      normal_queue_names.compact!
      priority_queue_names = @queues.map {|queue| queue.redis_name if queue.is_a_priority_queue? }
      priority_queue_names.compact!
      priority_queue_names.each do |queue_name|
        synchronize do
          begin
            @redis.watch queue_name
            payload = @redis.zrangebyscore(queue_name, MAX_PRIORITY, MIN_PRIORITY, {:limit => [0, 1]}).first
            if payload
              queue = @queue_hash[queue_name]
              status = @redis.multi do
                @redis.zrem queue_name, payload
              end
              raise RedisThreadSafetyViolationError unless status
              return [queue, queue.decode(payload)]
            end
          rescue RedisThreadSafetyViolationError
            retry
          end
        end
      end
      normal_queue_names = normal_queue_names.size == 0 ? "" : normal_queue_names
      queue_name, payload = @redis.blpop(normal_queue_names, :timeout => timeout)
      return unless payload

      synchronize do
        queue = @queue_hash[queue_name]
        [queue, queue.decode(payload)]
      end
    end
    alias :poll :poll_with_priority
  end
end
