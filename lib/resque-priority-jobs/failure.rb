module Resque
  module Failure
    def self.requeue(index)
      backend.requeue_with_priority(index)
    end
  end
end
