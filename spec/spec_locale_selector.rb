
require 'test/spec'
require 'rack/test'
require 'rack/locale_selector'

def mock_env(http_host, cookie = '', http_accept_locale = 'fr,en-EN;q=0.8')
  Rack::MockRequest.env_for(http_host, 'HTTP_COOKIE' => cookie, 'HTTP_ACCEPT_LANGUAGE' => http_accept_locale)
end

def request(options = {})
  Rack::MockRequest.new(Rack::LocaleSelector.new(@app, options))
end

describe "Rack::LocaleSelector" do
  
  before do
    @app = lambda { |env| [200, { }, 'hello'] }
  end
  
  context "request to root domain host" do
    before do
      I18n.default_locale = :en
    end
    
    it "should be redirected following cookie's value" do
      response = request.get 'http://example.com/', 'HTTP_COOKIE' => 'locale=fr'
      response.status.should.equal 301
      response.headers['Location'].should.equal 'http://fr.example.com/'
    end
    
    it "should be redirected following HTTP_ACCEPT_LANGUAGE headers" do
      response = request.get 'http://example.com/', 'HTTP_ACCEPT_LANGUAGE' => 'fr,en-EN;q=0.8'
      response.status.should.equal 301
      response.headers['Location'].should.equal 'http://fr.example.com/'
    end
    
    it "should be redirected using default locale if there's no HTTP_ACCEPT_LANGUAGE headers set" do
      response = request.get 'http://example.com/'
      response.status.should.equal 301
      response.headers['Location'].should.equal 'http://en.example.com/'
    end
  end
  
  context "request to domain host with locale set as subdomain" do
    it "should respond with spanish website" do
      response = request.get 'http://es.example.com/'
      response.status.should.equal 200
      response.headers['Set-Cookie'].should.equal "locale=es; domain=.example.com; path=/"
      I18n.locale.should.equal :es
    end
    
    it "should override cookie's value, set a new cookie and respond with spanish website" do
      response = request.get 'http://es.example.com/', 'HTTP_COOKIE' => 'locale=fr'
      response.status.should.equal 200
      response.headers["Set-Cookie"].should.equal "locale=es; domain=.example.com; path=/"
      I18n.locale.should.equal :es
    end
    
    it "should respond with spanish website" do
      response = request.get 'http://es.example.com/', 'HTTP_COOKIE' => 'locale=es'
      response.status.should.equal 200
      response.headers["Set-Cookie"].should.equal nil
      I18n.locale.should.equal :es
    end
  end
end