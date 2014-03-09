# Author::    Mohammad A. Ali  (mailto:oldmoe@gmail.com)
# Copyright:: Copyright (c) 2008 eSpace, Inc.
# License::   Distributes under the same terms as Ruby

require 'fiber'

class Fiber

  #Attribute Reference--Returns the value of a fiber-local variable, using
  #either a symbol or a string name. If the specified variable does not exist,
  #returns nil.
  def [](key)
    local_fiber_variables[key]
  end

  #Attribute Assignment--Sets or creates the value of a fiber-local variable,
  #using either a symbol or a string. See also Fiber#[].
  def []=(key,value)
    local_fiber_variables[key] = value
  end

  private

  def local_fiber_variables
    @local_fiber_variables ||= {}
  end
end

class FiberPool

  # gives access to the currently free fibers
  attr_reader :fibers
  attr_reader :busy_fibers

  # Code can register a proc with this FiberPool to be called
  # every time a Fiber is finished.  Good for releasing resources
  # like ActiveRecord database connections.
  attr_accessor :generic_callbacks

  # Prepare a list of fibers that are able to run different blocks of code
  # every time. Once a fiber is done with its block, it attempts to fetch
  # another one from the queue
  def initialize(count = 100)
    @fibers,@busy_fibers,@queue,@generic_callbacks = [],{},[],[]
    count.times do |i|
      fiber = Fiber.new do |block|
        loop do
          block.call
          # callbacks are called in a reverse order, much like c++ destructor
          Fiber.current[:callbacks].pop.call while Fiber.current[:callbacks].length > 0
          generic_callbacks.each do |cb|
            cb.call
          end
          unless @queue.empty?
            block = @queue.shift
          else
            @busy_fibers.delete(Fiber.current.object_id)
            @fibers.unshift Fiber.current
            block = Fiber.yield
          end
        end
      end
      fiber[:callbacks] = []
      fiber[:em_keys] = []
      @fibers << fiber
    end
  end

  # If there is an available fiber use it, otherwise, leave it to linger
  # in a queue
  def spawn(&block)
    if fiber = @fibers.shift
      fiber[:callbacks] = []
      @busy_fibers[fiber.object_id] = fiber
      fiber.resume(block)
    else
      @queue << block
    end
    self # we are keen on hiding our queue
  end

end


module Rack
  class FiberPool
    VERSION = '0.9.2'
    SIZE = 100

    # The size of the pool is configurable:
    #
    #   use Rack::FiberPool, :size => 25
    def initialize(app, options={})
      @app = app
      @fiber_pool = ::FiberPool.new(options[:size] || SIZE)
      @rescue_exception = options[:rescue_exception] || Proc.new { |env, e| [500, {}, "#{e.class.name}: #{e.message.to_s}"] }
      yield @fiber_pool if block_given?
    end

    def call(env)
      call_app = lambda do
        begin
          result = @app.call(env)
          env['async.callback'].call result
        rescue ::Exception => e
          env['async.callback'].call @rescue_exception.call(env, e)
        end
      end

      @fiber_pool.spawn(&call_app)
      throw :async
    end
  end
end
