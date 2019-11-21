# Cantaloupe delegate script

This project contains a Cantaloupe delegate script that can be used in conjunction with a local [Imagehub](https://github.com/kmska/ImageHub) and [ResourceSpace](https://www.resourcespace.com/get) (preferably with the [RS_ptif](https://github.com/kmska/RS_ptif) plugin installed). The code in this delegate script is specifically aimed toward authentication of a user through a locally installed third-party SAML service, for example the [Imagehub](https://github.com/kmska/ImageHub).


## Requirements

This project requires the following dependencies:
* [ResourceSpace](https://www.resourcespace.com/get) >= 9.1 with the [RS_ptif](https://github.com/kmska/RS_ptif) plugin installed
* A local [Imagehub](https://github.com/kmska/ImageHub) installation

# Usage

First of all, it is of the **utmost importance** that the following value is set to ``true`` in your cantaloupe.properties file, otherwise the authenticate method will not be called when fetching a cached image or info.json **and allow any unauthorized user to access private images inside the server cache**:

``cache.server.resolve_first = true``

Cantaloupe comes bundled with a sample delegate script ``delegates.rb.sample``, containing several delegate methods. The delegates.rb script in this project overrides the ``authenticate`` method.

In order to use the authentication in this project, you need to copy-paste the ``delegates.rb`` to a location of your choosing (for example into your cantaloupe installation folder) and set ``delegate_script.enabled = true`` and ``delegate_script.pathname = delegates.rb`` (or whatever your own delegate script is called) in cantaloupe.properties. The ``delegate_script.pathname`` can be a relative or an absolute path.

If you are already using a delegate script for other purposes, you can copy-paste the imports and the ``authenticate`` method from the delegates.rb file in this project into your own delegate script.

You also need to create a file called ``delegate_config.yml`` and put it in the same folder as the ``delegates.rb`` file. If you wish to name the config file diffently or place it in a different location, you need to alter the line ``config = YAML.load_file('delegate_config.yml')`` in ``delegates.rb`` to point it to the correct config file.

Copy-paste the following into the ``delegate_config.yml`` and alter these values as needed for your particular setup:
```
---
  # The keyword that the delegate script will look for in a request URL,
  # indicating that an image should not be publicly available
  # and authentication needs to be performed before being allowed access to this image or its info.json.
  private_keyword: 'private'

  # The URL that will be called to check if this user is already authenticated.
  # All cookies from the initial request will be passed along to this URL.
  # If the URL returns a 200 response code, all is OK, serve the image.
  # If it returns a 302 response code, the user needs to authenticate first.
  # Any other response codes than 200 or 302 will result in the user not being granted access.
  authcheck_url: 'https://imagehub.kmska.local/authcheck'

  # URL where to redirect the user if they are not yet authenticated.
  # This URL is expected to redirect back to here if authentication was successful.
  # The current request_uri will be appended to this URL so it knows where to redirect to.
  authenticator_url: 'https://imagehub.kmska.local/authenticate?url='

  # Any requests from these addresses will automatically be allowed.
  # This is needed for manifest generation inside an Imagehub.
  whitelist:
    - 127.0.0.1

```

delegate_config.yml
