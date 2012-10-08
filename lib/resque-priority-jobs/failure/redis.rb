module Resque
  module Failure
    class Redis < Base
      def self.requeue_with_priority(index)
        item = all(index)
        item['retried_at'] = Time.now.strftime("%Y/%m/%d %H:%M:%S")
        Resque.redis.lset(:failed, index, Resque.encode(item))
        if item['payload']['priority']
          Job.create_with_priority(item['queue'], item['payload']['class'], item['payload']['priority'], *item['payload']['args'])
        else
          Job.create(item['queue'], item['payload']['class'], *item['payload']['args'])
        end
      end
    end
  end
end
