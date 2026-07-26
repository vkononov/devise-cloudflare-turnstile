Rails.application.routes.draw do
  devise_for :users
  get 'dual_forms', to: 'pages#dual_forms'
  get 'widget_custom', to: 'pages#widget_custom'
  root to: 'pages#home'
end
