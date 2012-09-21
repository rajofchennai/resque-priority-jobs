module Resque
  class Queue
    # adds entry into redis
    def push_with_priority priority, object
      synchronize do
        @redis.zadd @redis_name, priority, encode(object)
      end
    end

    # remove entry from queue use default pop in case of non-priority queue see alias_method_chain
    def pop_with_priority non_block = false
      return pop_without_priority non_block unless is_a_priority_queue?
      synchronize do
        value = Resque::JobFetch.fetch_one_job @redis, @redis_name until non_block || value
        raise ThreadError if non_block && !value
        decode value
      end
    end
    alias :pop_without_priority :pop
    alias :pop :pop_with_priority

    def length
      @redis.type(@redis_name) == 'list' ? @redis.llen(@redis_name) : @redis.zcard(@redis_name)
    end
    alias :size :length

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

  end
end
