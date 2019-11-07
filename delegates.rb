require 'openssl'
require 'net/http'
require 'uri'

#
# Ruby delegate script for authentication against a SAML service
#
class CustomDelegate

  # Configuration of the authorize() method

  # The keyword that determines if a user needs to authenticate in order to access a file
  $private_keyword = 'private'

  # The URL that will be called to check if this user is already authenticated
  # All request cookies will be passed to this URL
  # If this URL returns a 200 response code, serve the image
  # If it returns a 302 response code, the user needs to authenticate
  # Any other response codes than 200 or 302 will result in the user not being allowed to access the image
  $authcheck_url = 'https://imagehub.kmska.be/imagehub/authcheck'

  # URL where to redirect the user if they are not yet authenticated
  # This URL is expected to redirect back to here if authentication was successful
  # The current request_uri will be appended to this URL so it knows where to redirect to
  $authenticator_url = 'https://imagehub.kmska.be/imagehub/authenticate?url='


  ##
  # Attribute for the request context, which is a hash containing information about the current request.
  #
  # @return [Hash] Request context.
  #
  attr_accessor :context

  ##
  # Returns authorization status for the current request. Will be called upon
  # all requests to all public endpoints.
  #
  # @param options [Hash] Empty hash.
  # @return [Boolean,Hash<String,Object>] See above.
  #
  def authorize(options = {})

    # Allow localhost to access all images (necessary for manifest generation in the imagehub)
    if context['client_ip'] == '127.0.0.1'
      true
    else
      # Determine if the URI contains the keyword 'private', indicating the user needs to authenticate first
      request_uri = context['request_uri']
      uri = URI.parse(request_uri)
      host_index = request_uri.index(uri.host) + uri.host.length
      path = request_uri[host_index..request_uri.length - 1]

      private_index = path.index($private_keyword)
      if private_index.nil?
        true
      else
        # Uses the Imagehub authenticator, requires local Imagehub Installation.
        # See https://github.com/kmska/Imagehub

        # First, check if the user is already authenticated
        uri = URI($authcheck_url)
        req = Net::HTTP::Get.new(uri)
        response = Net::HTTP.start(
                uri.host, uri.port,
                :use_ssl => uri.scheme == 'https',
                :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
          # Pass the SAML cookies (if any) to the authenticator
          req['Cookie'] = context['cookies']['Cookie']
          https.request(req)
        end

        # If the user is not (yet) authenticated, send them to the Imagehub authenticator to log in
        if response.code == '302'
          {
            'status_code' => 302,
            'location' => $authenticator_url + URI::encode(context['request_uri'])
          }
        # If the user is already authenticated, allow access to the image
        elsif response.code == '200'
          true
        # If any other response code is returned, disallow access to the image
        else
          false
        end
      end
    end
  end
end
