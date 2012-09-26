Hydrus::Application.routes.draw do
  mount AboutPage::Engine => '/about(.:format)'

  Blacklight.add_routes(self)
  HydraHead.add_routes(self)

  root :to => "catalog#index"

  devise_for :users

  # See how all your routes lay out with "rake routes"

  resources :collections, :controller => 'hydrus_collections', :as => 'hydrus_collections' do
    resources :events, :only=>:index
  end
  resources :items,       :controller => 'hydrus_items', :as => 'hydrus_items' do
    resources :events, :only=>:index
  end
  
  match "items/:id/destroy_value" => "hydrus_items#destroy_value", :as => 'destroy_hydrus_item_value', :via => "get"
  match "collections/:id/destroy_value" => "hydrus_collections#destroy_value", :as => 'destroy_hydrus_collection_value', :via => "get"
  match "collections/:id/destroy_actor" => "hydrus_collections#destroy_actor", :as => 'destroy_hydrus_collection_actor', :via => "get"
  match "users/auth/webauth" => "signin#login", :as => "webauth_login"
  match "users/auth/webauth/logout" => "signin#logout", :as => "webauth_logout"
  
  resources :object_files
  resources :signin
  

end
