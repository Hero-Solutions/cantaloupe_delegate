require 'openssl'
require 'net/http'
require 'uri'

##
# Ruby delegate script for authentication against a SAML service
#
# The application will create an instance of this class early in the request
# cycle and dispose of it at the end of the request cycle. Instances don't need
# to be thread-safe, but sharing information across instances (requests)
# **does** need to be done thread-safely.
#
# This version of the script works with Cantaloupe version 4, and not earlier
# versions. Likewise, earlier versions of the script are not compatible with
# Cantaloupe 4.
#
class CustomDelegate

  ##
  # Attribute for the request context, which is a hash containing information
  # about the current request.
  #
  # This attribute will be set by the server before any other methods are
  # called. Methods can access its keys like:
  #
  # ```
  # identifier = context['identifier']
  # ```
  #
  # The hash will contain the following keys in response to all requests:
  #
  # * `client_ip`        [String] Client IP address.
  # * `cookies`          [Hash<String,String>] Hash of cookie name-value pairs.
  # * `identifier`       [String] Image identifier.
  # * `request_headers`  [Hash<String,String>] Hash of header name-value pairs.
  # * `request_uri`      [String] Public request URI.
  # * `scale_constraint` [Array<Integer>] Two-element array with scale
  #                      constraint numerator at position 0 and denominator at
  #                      position 1.
  #
  # It will contain the following additional string keys in response to image
  # requests:
  #
  # * `full_size`      [Hash<String,Integer>] Hash with `width` and `height`
  #                    keys corresponding to the pixel dimensions of the
  #                    source image.
  # * `operations`     [Array<Hash<String,Object>>] Array of operations in
  #                    order of application. Only operations that are not
  #                    no-ops will be included. Every hash contains a `class`
  #                    key corresponding to the operation class name, which
  #                    will be one of the `e.i.l.c.operation.Operation`
  #                    implementations.
  # * `output_format`  [String] Output format media (MIME) type.
  # * `resulting_size` [Hash<String,Integer>] Hash with `width` and `height`
  #                    keys corresponding to the pixel dimensions of the
  #                    resulting image after all operations have been applied.
  #
  # @return [Hash] Request context.
  #
  attr_accessor :context

  ##
  # Returns authorization status for the current request. Will be called upon
  # all requests to all public endpoints.
  #
  # Implementations should assume that the underlying resource is available,
  # and not try to check for it.
  #
  # Possible return values:
  #
  # 1. Boolean true/false, indicating whether the request is fully authorized
  #    or not. If false, the client will receive a 403 Forbidden response.
  # 2. Hash with a `status_code` key.
  #     a. If it corresponds to an integer from 200-299, the request is
  #        authorized.
  #     b. If it corresponds to an integer from 300-399:
  #         i. If the hash also contains a `location` key corresponding to a
  #            URI string, the request will be redirected to that URI using
  #            that code.
  #         ii. If the hash also contains `scale_numerator` and
  #            `scale_denominator` keys, the request will be
  #            redirected using that code to a virtual reduced-scale version of
  #            the source image.
  #     c. If it corresponds to 401, the hash must include a `challenge` key
  #        corresponding to a WWW-Authenticate header value.
  #
  # @param options [Hash] Empty hash.
  # @return [Boolean,Hash<String,Object>] See above.
  #
  def authorize(options = {})

    # Determine if the URI contains the keyword 'private', indicating the user needs to authenticate first
    request_uri = context['request_uri']
    uri = URI.parse(request_uri)
    host_index = request_uri.index(uri.host) + uri.host.length
    path = request_uri[host_index..request_uri.length - 1]

    private_index = path.index('private')
    puts private_index
    if private_index.nil?
      true
    else
      # Uses the Imagehub authenticator, requires local Imagehub Installation.
      # See https://github.com/kmska/Imagehub

      # First, check if the user is already authenticated
      uri = URI('https://imagehub.kmska.be/imagehub/authcheck')
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
          'location' => 'https://imagehub.kmska.be/imagehub/authenticate?url=' + URI::encode(context['request_uri'])
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
