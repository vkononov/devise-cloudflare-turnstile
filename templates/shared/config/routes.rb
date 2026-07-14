Rails.application.routes.draw do
  devise_for :users
  get 'dual_forms', to: 'pages#dual_forms'
  root to: 'pages#home'
end
