module Resque
  class Queue
    # adds entry into redis
    def push_with_priority priority, object
      synchronize do
        @redis.zadd @redis_name, priority, encode(object)
      end
    end

    def push object
      raise QueueDestroyed if destroyed?
      puts object.inspect
      return push_with_priority object['priority'].to_i, object if object['priority']
      synchronize do
        @redis.rpush @redis_name, encode(object)
      end
    end

    alias :<< :push
    alias :enq :push

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

    def slice_with_priority(start, length)
      if @redis.type(@redis_name) == 'zset'
        if length == 1
          synchronize do
            @redis.zrangebyscore(@redis_name, '-inf', '+inf',  :limit =>[0,1] )
          end
        else
          synchronize do
            Array(@redis.zrangebyscore(@redis_name, '-inf', '+inf', :limit => [0, length])).map do |item|
              decode item
            end
          end
        end
      else
        slice_without_priority(start, length)
      end
    end

    alias :slice_without_priority :slice
    alias :slice :slice_with_priority

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
