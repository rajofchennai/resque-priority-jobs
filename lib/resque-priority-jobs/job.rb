module Resque
  class Job
    # checks if klass and queue are valid
    #FIXME: Not implemented Resque.inline?
    def self.create_with_priority queue, klass, priority, *args
      Resque.validate(klass, queue)
      Resque.push_with_priority(queue, priority, :class => klass.to_s, :args => args, :priority => priority)
    end
  end
end
