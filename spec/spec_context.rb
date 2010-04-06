# require "#{File.dirname(__FILE__)}/spec_setup"
# require 'rack/locale-selector/context'
# 
# module Rack::LocaleSelector
#   describe Context do
#     before(:each) { setup_locale_selector_context }
#     after(:each)  { teardown_locale_selector_context }
#   
#     context "Accessing a black listed resource should not select locale" do
#       it "should return the target app" do
#         get "/"
#         last_response.body.should contain("Target app")
#       end
#     end
# 
#     context "Accessing a white listed resource" do
#       it "should return the target app" do
#         get "/"
#         last_response.body.should contain("Target app")
#       end
#     end
#   end
# end