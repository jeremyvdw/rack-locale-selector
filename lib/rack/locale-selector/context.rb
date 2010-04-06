require 'rack/locale-selector/options'

module Rack::LocaleSelector
  # Implements Rack's middleware interface and provides the context for all
  # locale selection logic.
  class Context
    include Rack::LocaleSelector::Options

    def initialize(app, options={})
      @app = app
      @request =  Rack::Response.new(@env)
      
      initialize_options options
      yield self if block_given?
    end

    def call(env)
      if deflect?
        dispatch
      else
        @app.call(@env)
      end
    end

    def deflect?
      @subdomain = parse_host
      return !@option[:blacklist].include?(@subdomain) unless @option[:blacklist].empty?
      return !@option[:whitelist].include?(@subdomain) unless @option[:whitelist].empty?
    end

    def parse_host
      @request.host_with_port.split('.').first
      env["HTTP_HOST"].match(/^[a-z]{2}(?=\.)/)
    end

    def get_browser_language
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
      if lang = @env["HTTP_ACCEPT_LANGUAGE"]
        lang = lang.split(",").map { |l|
          l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
          l.split(';q=')
        }.first
        locale = options['rack-locale-selector.locale'] = lang.first.split("-").first
      else
        locale = options['rack-locale-selector.locale'] = I18n.default_locale
      end
      locale
    end

    def custom_domain?(host)
      domain = @default_domain.sub(/^\./, '')
      host !~ Regexp.new("#{domain}$", Regexp::IGNORECASE)
    end

    # def dispatch
    #   host = env.has_key?("HTTP_HOST") ? env["HTTP_HOST"].split(':').first : @default_domain
    #   @env["rack.session.options"][:domain] = custom_domain?(host) ? ".#{host}" : "#{@default_domain}" unless Rails.env == 'test'
    # 
    #   status, headers, body = builder.call(@env)
    #   @response = Rack::Response.new(body, status, headers)
    # 
    #   if @response.redirect? && options["rack-bug.intercept_redirects"]
    #     intercept_redirect
    #   elsif modify?
    #     inject_toolbar
    #   end
    # 
    #   return @response.to_a
    # end

    def dispatch
      # Coming from http://www.smartdate.com or http://whatever.smartdate.com
      if @subdomain == "www" or !locale_exist?(domain_locale)
        # Find the best locale
        I18n.locale = locale = env['rack.locale'] = if locale_exist?(cookies["language"])
          cookies["language"]
        elsif locale_exist?(get_language_from_browser(env).to_s.downcase)
          get_language_from_browser(env).to_s.downcase
        else
          I18n.default_locale
        end
        # puts "middleware: locale set to '#{locale}'\n" unless Rails.env == 'production'

        # If locale is english: continue
        # If the referer pointing to us we should change the language to english
        default_locale_str = I18n.default_locale.to_s
        if (locale == default_locale_str) or (locale != default_locale_str and env.has_key?("HTTP_REFERER") and env["HTTP_REFERER"].include?(env["HTTP_HOST"].sub(/www\./, '')))
          I18n.locale = locale = env['rack.locale'] = default_locale_str
          status, headers, body = @app.call(env)
          response = Rack::Response.new(body, status, headers)
          response.set_cookie("language", {:value => locale, :path => '/', :domain => env["rack.session.options"][:domain]}) unless cookies["language"] == default_locale_str
          # Fixes issue http://github.com/chneukirchen/rack/issues/#issue/3/comment/150615
          response.headers["Set-Cookie"].delete_if {|x| x.empty?} if response.headers["Set-Cookie"].is_a? Array
          return response.finish
        end

        # We redirect to the proper subdomain
        response = Rack::Response.new("Redirecting you to the #{locale} website.", 302, {"Location" => localized_url(env)})
        response.set_cookie("language", {:value => locale, :path => '/', :domain => env["rack.session.options"][:domain]})
        return response.finish
      end

      # Coming from http://<domain_locale>.smartdate.com
      I18n.locale = locale = env['rack.locale'] = @subdomain
      status, headers, body = @app.call(env)
      response = Rack::Response.new(body, status, headers)
      response.set_cookie("language", {:value => @subdomain, :path => '/', :domain => env["rack.session.options"][:domain]}) if domain_locale != cookies["language"]
      return response.finish
    end

    def log(message)
      return unless options[:log]
      options[:log].puts(options[:log_format] % [Time.now.strftime(options[:log_date_format]), message])
    end

  end

end