# require 'rubygems'
# require 'test/unit'
# require 'spec'
# require 'rack/test'
# require 'webrat'
# 
# $LOAD_PATH.unshift File.dirname(File.dirname(__FILE__)) + '/lib'
# 
# require 'rack/locale-selector'
# 
# Spec::Runner.configure do |config|
#   config.include Rack::Test::Methods
#   config.include Webrat::Matchers
# end
# 
# # Methods for constructing downstream applications / response
# # generators.
# module LocaleSelectorContextHelpers
# 
#   # The Rack::LocaleSelector::Context instance used for the most recent
#   # request.
#   attr_reader :locale_selector
# 
#   # An Array of Rack::LocaleSelector::Context instances used for each request, in
#   # request order.
#   attr_reader :locale_selectors
# 
#   # The Rack::Response instance result of the most recent request.
#   attr_reader :response
# 
#   # An Array of Rack::Response instances for each request, in request order.
#   attr_reader :responses
# 
#   # The backend application object.
#   attr_reader :app
# 
#   def setup_locale_selector_context
#     # holds each Rack::LocaleSelector::Context
#     @app = nil
# 
#     @locale_selector = nil
#     @locale_selectors = []
#     @errors = StringIO.new
#     @locale_selector_config = nil
# 
#     @called = false
#     @request = nil
#     @response = nil
#     @responses = []
#   end
# 
#   def teardown_locale_selector_context
#     @app, @locale_selector, @locale_selectors, @called,
#     @request, @response, @responses, @locale_selector_config = nil
#   end
# 
#   # A basic response with 200 status code and a tiny body.
#   def respond_with(status=200, headers={}, body=['Hello World'])
#     called = false
#     @app =
#       lambda do |env|
#         called = true
#         response = Rack::Response.new(body, status, headers)
#         request = Rack::Request.new(env)
#         yield request, response if block_given?
#         response.finish
#       end
#     @app.meta_def(:called?) { called }
#     @app.meta_def(:reset!) { called = false }
#     @app
#   end
# 
#   def locale_selector_config(&block)
#     @locale_selector_config = block
#   end
# 
#   def request(method, uri='/', opts={})
#     opts = {
#       'rack.run_once' => true,
#       'rack.errors' => @errors,
#     }.merge(opts)
# 
#     fail 'response not specified (use respond_with)' if @app.nil?
#     @app.reset! if @app.respond_to?(:reset!)
# 
#     @locale_selector_prototype ||= Rack::LocaleSelector::Context.new(@app, &@locale_selector_config)
#     @locale_selector = @locale_selector_prototype.clone
#     @locale_selectors << @locale_selector
#     @request = Rack::MockRequest.new(@locale_selector)
#     yield @locale_selector if block_given?
#     @response = @request.request(method.to_s.upcase, uri, opts)
#     @responses << @response
#     @response
#   end
# 
#   def get(stem, env={}, &b)
#     request(:get, stem, env, &b)
#   end
# 
#   def head(stem, env={}, &b)
#     request(:head, stem, env, &b)
#   end
# 
#   def post(*args, &b)
#     request(:post, *args, &b)
#   end
# end
# 
# class Test::Unit::TestCase
#   include LocaleSelectorContextHelpers
# end
