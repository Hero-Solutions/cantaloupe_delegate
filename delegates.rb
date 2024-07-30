require 'openssl'
require 'net/http'
require 'uri'
require 'yaml'

#
# Ruby delegate script for authentication against a SAML service
#
class CustomDelegate

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
  def pre_authorize(options = {})

    # Load configuration
    config = YAML.load_file('delegate_config.yml')

    # Allow localhost to access all images (necessary for manifest generation in the imagehub)
    if config['whitelist'].include? context['client_ip']
      true
    else
      # Determine if the URI contains the keyword 'private', indicating the user needs to authenticate first
      request_uri = context['request_uri']
      uri = URI.parse(request_uri)
      host_index = request_uri.index(uri.host) + uri.host.length
      path = request_uri[host_index..request_uri.length - 1]

      private_index = path.index(config['private_keyword'])
      if private_index.nil?
        true
      else
        # Uses the Imagehub authenticator, requires local Imagehub Installation.
        # See https://github.com/kmska/Imagehub

        # First, check if the user is already authenticated
        uri = URI(config['authcheck_url'])
        req = Net::HTTP::Get.new(uri)

        cookies_hash = context['cookies']
        cookies = cookies_hash.map { |k, v| "#{k}=#{v}" }.join('; ')

        response = Net::HTTP.start(
                uri.host, uri.port,
                :use_ssl => uri.scheme == 'https',
                :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
          # Pass the SAML cookies (if any) to the authenticator
          req['Cookie'] = cookies
          https.request(req)
        end

        # If the user is not (yet) authenticated, send them to the Imagehub authenticator to log in
        if response.code == '302'
          {
            'status_code' => 302,
            'location' => config['authenticator_url'] + URI::encode(context['request_uri'])
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

  def authorize(options = {})
    true
  end

  def metadata(options = {})
  end

  def redactions(options = {})
    []
  end

  def extra_iiif2_information_response_keys(options = {})
    extra_information_response_keys
  end

  def extra_iiif3_information_response_keys(options = {})
    extra_information_response_keys
  end

  def extra_information_response_keys
    {
      'exif' => context.dig('metadata', 'exif'),
      'iptc' => context.dig('metadata', 'iptc')
    }
  end

end
