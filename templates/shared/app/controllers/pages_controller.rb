class PagesController < ApplicationController
  def home; end

  def dual_forms
    @_devise_turnstile_protected = true
  end
end
