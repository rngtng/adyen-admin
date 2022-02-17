$:.unshift File.expand_path("../../lib", __FILE__)

require "adyen-admin"
require "yaml"
require "vcr"

$adyen = YAML::load( (File.open('credentials.yml') rescue File.open('credentials.yml.example')) )

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding == Encoding::BINARY ||
    !http_message.body.valid_encoding?
  end
  c.allow_http_connections_when_no_cassette = true

  $adyen.each do |key, value|
    if value.is_a?(Array)
      value.each_with_index do |v, index|
        c.filter_sensitive_data("<#{key}-#{index}>") { v }
      end
    else
      c.filter_sensitive_data("<#{key}>") { value }
    end
  end

end

RSpec.configure do |c|
  # so we can use `:vcr` rather than `:vcr => true`;
  # in RSpec 3 this will no longer be necessary.
  c.treat_symbols_as_metadata_keys_with_true_values = true
end
