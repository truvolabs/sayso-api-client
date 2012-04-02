require 'oauth'
require 'crack'
require 'active_support/all'
#
# Example usage:
#  sayso = Sayso.new(:consumer_key => 'your_key', :consumer_secret => 'your_secret', :callback => 'http://localhost:3000')
#  sayso = Sayso.new(:consumer_key => sayso_key, :consumer_secret => sayso_secret, :callback => 'http://localhost:3000')
#  sayso.get("/places/search?what=restaurant&where=antwerpen")
#  sayso.get("/places/search", :what => 'restaurant', :where => 'antwerpen')
#  sayso.authorize_url # go here (=> "http://api.sayso.com/api1/oauth/authorize?oauth_token=some_token_hash")
#  sayso.authorize_access_token('verifier')
#  sayso.get_params # => 
#  sayso.get("/users/current")
#  sayso.get('/places/cj5C4oyiCr3Ra2aby-7U4a/reviews')
#  review = '<?xml version="1.0" encoding="UTF-8"?><review><rating>2</rating><text>This is my review number 1. It is not so long but states that it works. We can see that everything is ok.</text></review>'
#  sayso.post('/places/cj5C4oyiCr3Ra2aby-7U4a/reviews', review)
#
class Sayso

  attr_accessor :version, :consumer_key, :consumer_secret, :base_url, :callback, :get_params
  attr_reader :access_token, :request_token, :response, :consumer

  # Example:
  #  Sayso.new(:consumer_key => 'your_key', :consumer_secret => 'your_secret', :language => 'nl-NL')
  # The language parameter is optional.
  def initialize(options = {})
    options = {:version => 1, :base_url => 'http://api.sayso.com', :callback => nil}.merge(options)

    # The language options is set to the get_params.
    @get_params = {}
    @get_params[:language] = options.delete(:language) if options[:language]

    # All other options should be set to the related instance variable.
    options.each do |attr, value|
      instance_variable_set(:"@#{attr}", value)
    end
    self.initialize_access_token
  end

  def initialize_access_token(force = false)
    return @access_token if force || !@access_token.nil?
    @consumer = OAuth::Consumer.new(self.consumer_key, self.consumer_secret, {
      :site => self.base_url,
      :request_token_path => "/api#{self.version}/oauth/request_token",
      :authorize_path => "/api#{self.version}/oauth/authorize",
      :access_token_path => "/api#{self.version}/oauth/access_token" })
    @request_token = @consumer.get_request_token(:oauth_callback => callback)
    # Just make it using the request token (and a user that has given access ?!)
    @access_token = OAuth::AccessToken.new(@consumer, @request_token.token, @request_token.secret)
  end

  # Returns the url where to send the user to authenticate himself.
  # After this call the authorize_access_token method to authenticate
  # the session and be able to use write access and current_user methods.
  def authorize_url
    @request_token.authorize_url
  end

  # Go to the given url (see authorize_url) and you get redirected to, eg:
  #  http://localhost:3000/?oauth_token=DGJb7aPa1XrY82a8hmJVp6IbF0qLZ9Je0pO4B7qF&oauth_verifier=iWhKZfIjPDjozBRhSDoA
  # Call this method with the correct oauth_verifier as argument.
  def authorize_access_token(oauth_verifier)
    @access_token = @request_token.get_access_token(:oauth_verifier => oauth_verifier)
  end

  # Gets from the Sayso API and returns the parsed XML.
  # Access the unparsed response using the response method.
  # Examples:
  #  get("/places/search?what=restaurant&where=antwerpen&base_country=BE")
  #  get("/places/search", :what => 'restaurant', :where => 'antwerpen', :base_country => 'BE')
  def get(path, params = {})
    params = params.with_indifferent_access
    # We should always include a base_country in searches.
    raise ArgumentError, "You should add a :country parameter to a search request to prevent weird/incorrect replies." if path =~ /^\/places\/search/ && !(params.include?(:base_country) || path =~ /(\?|&)base\_country\=/)

    path = "/api#{self.version}#{path}"
    path += "?#{params.to_query}" unless params.blank?
    @response = @access_token.get(path)
    raise StandardError, "Got non 200 HTTP response from SaySo" if not @response.code == '200'
    result = Crack::XML.parse(@response.body)
    HashWithIndifferentAccess.new(result)
  end

  # Examples:
  #  post('/places/:place_id/reviews', :rating => 3, :text => "My review text that should be a certain length.")
  def post(path, params = {})
    path = "/api#{self.version}#{path}"
    @response = @access_token.post(path, params, { 'Accept'=>'application/xml', 'Content-Type' => 'application/xml' })
    result = Crack::XML.parse(@response.body)
    HashWithIndifferentAccess.new(result)
  end

end