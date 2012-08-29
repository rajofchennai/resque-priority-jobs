module Resque
  class RedisThreadSafetyViolationError < StandardError
  end
  class Queue
    # adds entry into redis
    def push_with_priority priority, object
      synchronize do
        @redis.zadd @redis_name, normalize(priority), encode(object)
      end
    end

    # remove entry from queue use default pop in case of non-priority queue see alias_method_chain
    def pop_with_priority non_block = false
      return pop_without_priority non_block unless is_a_priority_queue?
      synchronize do
        begin
          @redis.watch @redis_name
          value = @redis.zrangebyscore(@redis_name, MAX_PRIORITY, MIN_PRIORITY, {:limit => [0, 1]}).first until non_block || value
          raise ThreadError if non_block && !value
          status = @redis.multi do
            @redis.zrem @redis_name, value
          end
          raise RedisThreadSafetyViolationError unless status
          decode value
        rescue RedisThreadSafetyViolationError
          retry
        end
      end
    end
    alias_method_chain :pop, :priority

    # not optimial has an extra redis call for priority call. Assumtion is that there are lesser queues using priority
    def length
      @redis.llen @redis_name rescue @redis.zcard @redis_name
    end

    # To identify whether a queue is priority queue or not. Empty queues are always non-priority
    # Assumption : Once a queue type is set to be a priority queue, it cannot be changed and vice-versa.
    def is_a_priority_queue?
      @@queue_types ||= {}
      (@@queue_types[@redis_name] ||= queue_type) == 'zset'
    end

    def queue_type
      type = @redis.type(@redis_name)
      type == 'none' ? nil : type
    end

    private

    # restricting the maximum and minimum priority. I do't think this is needed, extending priority to -inf to +inf should not cause any problems
    def normalize priority
      if priority > MIN_PRIORITY
        MIN_PRIORITY
      elsif priority < MAX_PRIORITY
        MAX_PRIORITY
      else
        priority
      end
    end
  end
end
