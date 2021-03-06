require_relative "../../test_helper"

class Test::Proxy::Caching::TestAuth < Minitest::Test
  include ApiUmbrellaTestHelpers::Setup
  include ApiUmbrellaTestHelpers::Caching
  parallelize_me!

  def setup
    setup_server
    once_per_class_setup do
      prepend_api_backends([
        {
          :frontend_host => "127.0.0.1",
          :backend_host => "127.0.0.1",
          :servers => [{ :host => "127.0.0.1", :port => 9444 }],
          :url_matches => [{ :frontend_prefix => "/#{unique_test_class_id}/add-auth-header/", :backend_prefix => "/" }],
          :settings => {
            :http_basic_auth => "somebody:secret",
          },
        },
      ])
    end
  end

  def test_does_not_cache_requests_with_external_authorization_header
    refute_cacheable("/api/cacheable-cache-control-max-age/", {
      :headers => {
        "Authorization" => "foo",
      },
    })
  end

  def test_caches_requests_that_send_api_key_as_username
    assert_cacheable("/api/cacheable-cache-control-max-age/", {
      :userpwd => "#{self.api_key}:",
    })
  end

  def test_does_not_cache_requests_that_send_non_api_key_as_username
    refute_cacheable("/api/cacheable-cache-control-max-age/", {
      :userpwd => "something:",
    })
  end

  def test_does_not_cache_responses_with_www_authenticate
    refute_cacheable("/api/cacheable-www-authenticate/")
  end

  def test_caches_requests_that_add_auth_at_proxy
    assert_cacheable("/#{unique_test_class_id}/add-auth-header/cacheable-cache-control-max-age/")
  end

  def test_does_not_cache_uncacheable_requests_that_add_auth_at_proxy
    refute_cacheable("/#{unique_test_class_id}/add-auth-header/cacheable-cache-control-max-age/", {
      :headers => {
        "Cookie" => "foo",
      },
    })
  end

  def test_ignores_internal_authorization_headers_set_externally
    refute_cacheable("/api/cacheable-cache-control-max-age/", {
      :userpwd => "something:",
      :headers => {
        "X-Api-Umbrella-Allow-Authorization-Caching" => "true",
      },
    })
  end
end
