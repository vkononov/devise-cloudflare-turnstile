# Webpacker 4/5 still call File.exists? / Dir.exists?, removed in Ruby 3.2.
class << File
  alias exists? exist? unless method_defined?(:exists?)
end

class << Dir
  alias exists? exist? unless method_defined?(:exists?)
end
