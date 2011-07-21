require 'oauth'
require 'crack'
require 'active_support/all'
#
# Example usage:
#  sayso = Sayso.new(:consumer_key => 'your_key', :consumer_secret => 'your_secret')
#  sayso.get("/places/search?what=restaurant&where=antwerpen")
#  sayso.get("/places/search", :what => 'restaurant', :where => 'antwerpen')
#  sayso.authorize_url # go here (=> "http://api.sayso.com/api1/oauth/authorize?oauth_token=some_token_hash")
#  sayso.authorize_access_token('verifier')
#  sayso.get("/users/current")
#
class Sayso

  attr_accessor :version, :consumer_key, :consumer_secret, :base_url, :callback
  attr_reader :access_token, :request_token, :response

  def initialize(options = {})
    options = {:version => 1, :base_url => 'http://api.sayso.com', :callback => nil}.merge(options)
    options.each do |attr, value|
      instance_variable_set(:"@#{attr}", value)
    end
    self.initialize_access_token
  end

  def initialize_access_token
    return @access_token unless @access_token.nil?
    @consumer = OAuth::Consumer.new(self.consumer_key, self.consumer_secret, {
      :site => self.base_url,
      :request_token_path => "/api#{self.version}/oauth/request_token",
      :authorize_path => "/api#{self.version}/oauth/authorize",
      :access_token_path => "/api#{self.version}/oauth/access_token" })
    @request_token = @consumer.get_request_token(:oauth_callback => "http://localhost:3000")
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
  #  get("/places/search?what=restaurant&where=antwerpen")
  def get(path, params = {})
    path = "/api#{self.version}#{path}"
    path += "?#{params.to_query}" unless params.blank?
    @response = @access_token.get(path)
    result = Crack::XML.parse(@response.body)
    HashWithIndifferentAccess.new(result)
  end

  # TODO
  # def post/put
  # end

end