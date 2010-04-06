require 'test/spec'
require 'rack/mock'
require 'rack/locale_selector'

def mock_env(http_host, path = '/', cookie = '', http_accept_language = 'fr,en-EN;q=0.8')
  opts = {'HTTP_HOST' => http_host}
  opts.merge!({'HTTP_COOKIE' => cookie}) if cookie
  opts.merge!({'HTTP_ACCEPT_LANGUAGE' => http_accept_language}) if http_accept_language
  Rack::MockRequest.env_for(path, opts)
end

def middleware(options = {})
  Rack::LocaleSelector.new(@app, options)
end

describe "Rack::LocaleSelector" do

  before do
    @app = lambda { |env| [200, { 'Content-Type' => 'text/plain' }, 'hello'] }
  end
  
  context "Root domain host without cookie does redirect" do
    before do
      @app = middleware
    end
    
    it "should follow HTTP_ACCEPT_LANGUAGE headers" do
      status, headers, body = @app.call(mock_env("example.com"))
      status.should.equal 403
      I18n.locale.should.equal 'fr'
      headers["Set-Cookie"].should.equal "language=fr"
      headers["Location"].should.equal "fr.example.com"
    end
    
    it "should follow default locale if no HTTP_ACCEPT_LANGUAGE headers" do
      status, headers, body = @app.call(mock_env('example.com', '/', '', false))
      status.should.equal 403
      I18n.locale.should.equal 'en'
      headers["Set-Cookie"].should.equal "language=en"
      headers["Location"].should.equal "en.example.com"
    end
  end
  
  context "Root domain host with cookie" do
    specify "redirect should follow cookie's value" do
      app = middleware
      status, headers, body = @app.call(mock_env("example.com", '/', 'language=fr'))
      status.should.equal 403
      I18n.locale.should.equal 'fr'
      headers["Set-Cookie"].should.equal "language=fr"
      headers["Location"].should.equal "fr.example.com"
    end
    
    specify "should be redirected to spanish website" do
      app = middleware
      status, headers, body = @app.call(mock_env("example.com", '/', 'language=es'))
      status.should.equal 403
      I18n.locale.should.equal 'es'
      headers["Set-Cookie"].should.equal ""
      headers["Location"].should.equal "es.example.com"
    end
  end
  
  context "Home page with cookie" do
    specify "should be redirected to french website with french locale (when cookie)" do
      app = middleware
      status, headers, body = @app.call(mock_env('www.example.com', '/', 'language=fr'))
      status.should.equal 403
      I18n.locale.should.equal 'fr'
      headers["Set-Cookie"].should.equal ""
      headers["Location"].should.equal "fr.example.com"
    end
  end
  
  context "Locale page without cookie" do
    specify "should display the french website with french locale and set a cookie" do
      app = middleware
      status, headers, body = @app.call(mock_env('fr.example.com'))
      status.should.equal 200
      I18n.locale.should.equal 'fr'
      headers["Set-Cookie"].should.equal "language=fr"
    end
  end

  context "Locale page with cookie" do
    specify "should display the french website with french locale" do
      app = middleware
      status, headers, body = @app.call(mock_env('fr.example.com', '/', 'language=fr'))
      status.should.equal 200
      I18n.locale.should.equal 'fr'
      headers["Set-Cookie"].should.equal ''
    end
  end

end