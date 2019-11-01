# Cantaloupe delegate script

This project contains a Cantaloupe delegate script that can be used in conjunction with a local [Imagehub](https://github.com/kmska/ImageHub) and [ResourceSpace](https://www.resourcespace.com/get) (preferably with the [RS_ptif](https://github.com/kmska/RS_ptif) plugin installed). The code in this delegate script is specifically aimed toward authentication of a user through a locally installed third-party SAML service, for example the [Imagehub](https://github.com/kmska/ImageHub).


## Requirements

This project requires the following dependencies:
* [ResourceSpace](https://www.resourcespace.com/get) >= 9.1 with the [RS_ptif](https://github.com/kmska/RS_ptif) plugin installed
* A local [Imagehub](https://github.com/kmska/ImageHub) installation

# Usage

Cantaloupe comes bundled with a sample delegate scrips ``delegates.rb.sample``, containing several delegate methods. The delegates.rb script in this project overrides the ``authenticate`` method.

In order to use the authentication in this project, you need to copy-paste the complete ``delegates.rb`` into your cantaloupe installation folder or copy-paste the imports. If you are already using the delegate script for other purposes, then you can copy-paste the imports, the ``@@private_keyword``, ``@@authcheck_url`` and ``@@authenticator_url`` values and the ``authenticate`` method from the delegates.rb file in this project into your delegate script.

You also need to set ``delegate_script.enabled = true`` and ``delegate_script.pathname = delegates.rb`` (or whatever your own delegate script is called) in cantaloupe.properties.
