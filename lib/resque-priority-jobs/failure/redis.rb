module Resque
  module Failure
    class Redis < Base
      class << self
        alias :requeue_without_priority :requeue
      end
      def self.requeue_with_priority(index)
        item = all(index)
        item['retried_at'] = Time.now.strftime("%Y/%m/%d %H:%M:%S")
        Resque.redis.lset(:failed, index, Resque.encode(item))
        puts item.inspect
        if item['payload']['priority']
          Job.create_with_priority(item['queue'], item['payload']['class'], item['payload']['priority'], *item['payload']['args'])
        else
          Job.create(item['queue'], item['payload']['class'], *item['payload']['args'])
        end
      end
      class << self
        alias :requeue :requeue_with_priority
      end
    end
  end
end
