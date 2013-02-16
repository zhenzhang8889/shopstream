module ActiveSupport
  module Cache
    class RedisStore < Store
      def initialize(address = nil, options = nil)
        address = Redis.current unless address
        @data = address.is_a?(Redis) ? address : Redis.new(address)
        super(options)
      end

      def increment(key, amount = 1)
        instrument(:increment, key, amount: amount) do
          @data.incrby(key, amount)
        end
      end

      def decrement(key, amount = 1)
        instrument(:decrement, key, amount: amount) do
          @data.decrby(key, amount)
        end
      end

      def clear
        instrument(:clear, nil, nil) do
          @data.flushdb
        end
      end

      def stats
        @data.info
      end

      protected

      def write_entry(key, entry, options = {})
        method = options[:unless_exist] ? :setnx : :set
        value = entry.raw_value
        expires_in = options[:expires_in].to_i

        @data.multi do
          @data.send(method, key, value)
          @data.expire(key, expires_in) if expires_in > 0
        end

        true
      rescue Errno::ECONNREFUSED
        false
      end

      def read_entry(key, options = {})
        raw_value = @data.get(key)

        if raw_value
          value = Marshal.load(raw_value) rescue raw_value
          Entry.new(value)
        end
      rescue Errno::ECONNREFUSED
        nil
      end

      def delete_entry(key, options = nil)
        @data.del(key)
      rescue Errno::ECONNREFUSED
        false
      end
    end
  end
end
