require 'rubygems'
require 'i18n'

module Rack
  class LocaleSelector
    
    attr_reader :options
    
    def initialize(app, options={})
      @app = app
      @options = {
        :use_domain => true
      }.merge(options)
      yield self if block_given?
    end

    def call(env)
      env = env
      request = Rack::Request.new(env)

      # get subdomain and domain
      # subdomain, domain = split_domain(host)
      # We need to set cookies domain to ".example.com" (see http://codetunes.com/2009/04/17/dynamic-cookie-domains-with-racks-middleware/)
      host = @env['HTTP_HOST'].split(':').first if @env.has_key?('HTTP_HOST')
      @env['rack.session.options'][:domain] = custom_domain?(host) ? ".#{host}" : @options[:default_domain]
      
      if deflect?(request)
        dispatch
      else
        @app.call(@env)
      end
    end

    def custom_domain?(host)
      domain = @default_domain.sub(/^\./, '')
      host !~ Regexp.new("#{domain}$", Regexp::IGNORECASE)
    end

    def deflect?(request)
      subdomain = parse_host(request.host)
      return !@option[:blacklist].include?(subdomain) unless @option[:blacklist].empty?
      return !@option[:whitelist].include?(subdomain) unless @option[:whitelist].empty?
    end

    # Return HTTP_HOST subdomain (ie fr.example.com => fr)
    def parse_host(host)
      return host.match(/^[a-z0-9]{2}(?=\.)/)[0] if @options[:use_domain]
    end

    def get_browser_language
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
      if lang = @env["HTTP_ACCEPT_LANGUAGE"]
        lang = lang.split(",").map { |l|
          l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
          l.split(';q=')
        }.first
        locale = options['rack.locale'] = lang.first.split("-").first
      else
        locale = options['rack.locale'] = I18n.default_locale
      end
      locale
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
        I18n.locale = locale = env['rack.locale'] = if locale_exist?(@cookies["language"])
          @cookies["language"]
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
          response.set_cookie("language", {:value => locale, :path => '/', :domain => @env["rack.session.options"][:domain]}) unless @cookies["language"] == default_locale_str
          # Fixes issue http://github.com/chneukirchen/rack/issues/#issue/3/comment/150615
          response.headers["Set-Cookie"].delete_if {|x| x.empty?} if response.headers["Set-Cookie"].is_a? Array
          return response.finish
        end

        # We redirect to the proper subdomain
        response = Rack::Response.new("Redirecting you to the #{locale} website.", 302, {"Location" => localized_url(env)})
        response.set_cookie("language", {:value => locale, :path => '/', :domain => @env["rack.session.options"][:domain]})
        return response.finish
      end

      # Coming from http://<domain_locale>.smartdate.com
      I18n.locale = locale = env['rack.locale'] = @subdomain
      status, headers, body = @app.call(env)
      response = Rack::Response.new(body, status, headers)
      response.set_cookie("language", {:value => @subdomain, :path => '/', :domain => @env["rack.session.options"][:domain]}) if domain_locale != @cookies["language"]
      return response.finish
    end

    def log(message)
      return unless options[:log]
      options[:log].puts(options[:log_format] % [Time.now.strftime(options[:log_date_format]), message])
    end
    
    def set_locale(locale)
      I18n.locale = env['rack.locale'] = locale.to_sym
    end
  end
end