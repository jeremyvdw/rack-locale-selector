module Rack::LocaleSelector
  # Configuration options and utility methods for option access. Rack::LocaleSelector
  # uses the Rack Environment to store option values. All options documented
  # below are stored in the Rack Environment as "rack-locale-selector.<option>", where
  # <option> is the option name.
  module Options
    class << self
      private
      def option_accessor(key)
        define_method(key) { || read_option(key) }
        define_method("#{key}=") { |value| write_option(key, value) }
        define_method("#{key}?") { || !! read_option(key) }
      end
    end

    # Enable verbose trace logging. This option is currently enabled by
    # default but is likely to be disabled in a future release.
    option_accessor :verbose

    # The underlying options Hash. During initialization (or outside of a
    # request), this is a default values Hash. During a request, this is the
    # Rack environment Hash. The default values Hash is merged in underneath
    # the Rack environment before each request is processed.
    def options
      @env || @default_options
    end

    # Set multiple options.
    def options=(hash={})
      hash.each { |key,value| write_option(key, value) }
    end

    # Set an option. When +option+ is a Symbol, it is set in the Rack
    # Environment as "rack-locale-selector.option". When +option+ is a String, it
    # exactly as specified. The +option+ argument may also be a Hash in
    # which case each key/value pair is merged into the environment as if
    # the #set method were called on each.
    def set(option, value=self, &block)
      if block_given?
        write_option option, block
      elsif value == self
        self.options = option.to_hash
      else
        write_option option, value
      end
    end

  private

    def read_option(key)
      options[option_name(key)]
    end

    def write_option(key, value)
      options[option_name(key)] = value
    end

    def option_name(key)
      case key
      when Symbol ; "rack-locale-selector.#{key}"
      when String ; key
      else raise ArgumentError
      end
    end

    def initialize_options(options={})
      @default_options = {
        'rack-locale-selector.locale' => nil,
        'rack-locale-selector.verbose' => nil
      }
      self.options = options
    end

  end
end
