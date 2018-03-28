require 'net/http'
require 'json'
require_relative 'uri_builder'

module Coyodlee
  class CobrandLoginRequest
    def initialize(uri_builder:)
      @uri_builder = uri_builder
    end

    def build(login_name:, password:)
      uri = @uri_builder.build('cobrand/login')
      Net::HTTP::Post.new(uri).tap do |req|
        req.body = {
          cobrand: {
            cobrandLogin: login_name,
            cobrandPassword: password,
            locale: 'en_US'
          }
        }.to_json
        req['Content-Type'] = 'application/json'
        req['Accept'] = 'application/json'
      end
    end
  end

  class RequestExecutor
    def initialize(facade)
      @facade = facade
    end

    def execute(klass, params)
      uri_builder = @facade.uri_builder
      http = @facade.http
      req = klass.new(uri_builder: uri_builder)
              .build(params)
      http.request(req)
    end
  end

  class RequestFacade
    attr_reader :http
    attr_reader :uri_builder

    def initialize(http:, uri_builder:)
      @http = http
      @uri_builder = uri_builder
    end

    def cobrand_login(login_name:, password:)
      RequestExecutor.new(self)
        .execute(CobrandLoginRequest, login_name: login_name, password: password)
    end
  end

  class Connection
    class << self
      def create
        new UriBuilder.new(host: Coyodlee.host)
      end
    end

    def initialize(uri_builder)
      @uri_builder = uri_builder
    end

    def start(&block)
      Net::HTTP.start('developer.api.yodlee.com', use_ssl: true) do |http|
        yield RequestFacade.new(http: http, uri_builder: @uri_builder)
      end
    end
  end
end
