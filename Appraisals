# Rails 6 is not exercised on Ruby 3.2+ (stdlib / compatibility gaps).
if RUBY_VERSION < '3.2.0'
  appraise 'rails-6.0' do
    gem 'rails', '~> 6.0.0'
  end

  appraise 'rails-6.1' do
    gem 'rails', '~> 6.1.0'
  end
end

if RUBY_VERSION >= '2.7.0' && RUBY_VERSION < '4.0.0'
  appraise 'rails-7.0' do
    gem 'rails', '~> 7.0.0'
    if RUBY_VERSION >= '3.4.0'
      gem 'drb'
      gem 'mutex_m'
    end
  end
end

if RUBY_VERSION >= '2.7.0'
  appraise 'rails-7.1' do
    gem 'rails', '~> 7.1.0'
  end
end

if RUBY_VERSION >= '3.1.0'
  appraise 'rails-7.2' do
    gem 'rails', '~> 7.2.0'
  end
end

if RUBY_VERSION >= '3.2.0'
  appraise 'rails-8.0' do
    gem 'rails', '~> 8.0.0'
  end

  appraise 'rails-8.1' do
    gem 'rails', '~> 8.1.0'
  end
end
