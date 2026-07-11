require 'test_helper'

class TurnstileVersionTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Devise::Cloudflare::Turnstile::VERSION
  end
end
