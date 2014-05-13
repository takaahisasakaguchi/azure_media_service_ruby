module AzureMediaServiceRuby
  class Request

    def initialize(config)
      build_config(config) 
    end

    def get(endpoint, params={})

      setToken()

      res = conn(@config[:mediaURI]).get do |req|
        req.url endpoint
        req.headers = @default_headers
        req.headers[:Authorization] = "Bearer #{@access_token}"
        req.params = params
      end

      res.body
    end

    private
    def build_config(config)

      @config = config || {}
      # @config[:mediaURI] = "https://media.windows.net/API/"
      @config[:mediaURI] = "https://wamsos1clus001rest-hs.cloudapp.net/api"
      @config[:tokenURI] = "https://wamsprodglobal001acs.accesscontrol.windows.net/v2/OAuth2-13"
      @config[:client_id] ||= ''
      @config[:client_secret] ||= ''

      @default_headers = {
        "Content-Type"          => "application/json;odata=verbose",
        "Accept"                => "application/json;odata=verbose",
        "DataServiceVersion"    => "3.0",
        "MaxDataServiceVersion" => "3.0",
        "x-ms-version"          => "2.5"
      }
    end

    def conn(url)
      conn = Faraday::Connection.new(:url => url, :ssl => {:verify => false}) do |builder|
        builder.request :url_encoded
        builder.response :logger
        builder.use FaradayMiddleware::EncodeJson
        builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
        builder.adapter Faraday.default_adapter
      end
    end

    def setToken
      res = conn(@config[:tokenURI]).post do |req|
        req.body = {
          client_id: @config[:client_id], 
          client_secret: @config[:client_secret],
          grant_type: 'client_credentials',
          scope: 'urn:WindowsAzureMediaServices'
        }
      end

      p res.body
      @access_token = res.body["access_token"]
      @token_expires = Time.now.to_i + res.body["expires_in"].to_i
    end
  end
end