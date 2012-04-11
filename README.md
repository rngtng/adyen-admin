# Adyen Admin  [![](http://travis-ci.org/rngtng/adyen-admin.png)](http://travis-ci.org/rngtng/adyen-admin)

Adyen Admin Skin API and Command line tool

A little Gem to make your life easier when dealing with Adyen skins. It offers simple functions to maniu

## Setup
Install gem

    gem install adyen-admin

Make sure you create a Adyen user with [Technical Setting rights](https://ca-test.adyen.com/ca/ca/config/users.shtml). *Std user rights have to be given as well!*


## Usage

Simple usage case to get all Skins:

```ruby
require 'adyen/admin'

Adyen::Admin.login(<accountname>, <username>, <password>)

Adyen::Admin::Skin.all  #returns all remote + local skins

```

### Skins

By now a Skin can be:

  * downloaded
  * uploaded
  * compiled
  * retrieve versions
  * retrieve test_url
  * map to local or remote

## Dependencies

Depends on [mechanize](http://mechanize.rubyforge.org/) to access the webinterface


## Contributing

We'll check out your contribution if you:

- Provide a comprehensive suite of tests for your fork.
- Have a clear and documented rationale for your changes.
- Package these up in a pull request.

We'll do our best to help you out with any contribution issues you may have.


## License

The license is included as LICENSE in this directory.
