Hydrus::Application.routes.draw do
  mount AboutPage::Engine => '/about(.:format)'

  Blacklight.add_routes(self)
  HydraHead.add_routes(self)

  root :to => "catalog#index"

  devise_for :users

  # See how all your routes lay out with "rake routes"

  resources :collections, :controller => 'hydrus_collections', :as => 'hydrus_collections'
  resources :items,       :controller => 'hydrus_items', :as => 'hydrus_items'

  resources :collections, :controller => 'hydrus_collections', :as => 'dor_collections'
  resources :items,       :controller => 'hydrus_items', :as => 'dor_items'
  
  match "items/:id/destroy_value" => "hydrus_items#destroy_value", :as => 'destroy_hydrus_item_value', :via => "get"
  match "collections/:id/destroy_value" => "hydrus_collections#destroy_value", :as => 'destroy_hydrus_collection_value', :via => "get"
  match "collections/:id/destroy_actor" => "hydrus_collections#destroy_actor", :as => 'destroy_hydrus_collection_actor', :via => "get"

  resources :object_files
  resources :signin

end
