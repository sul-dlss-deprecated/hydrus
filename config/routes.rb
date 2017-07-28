Hydrus::Application.routes.draw do
  HydraHead.add_routes(self)

  root to: 'catalog#home'
  get 'catalog' => 'catalog#index', :as => :catalog_index

  devise_for :users, controllers: { sessions: 'sessions' }

  # Actions to advance Collections through the Hydrus process.
  post 'collections/open/:id'  => 'hydrus_collections#open',     :as => 'open_collection'
  post 'collections/close/:id' => 'hydrus_collections#close',    :as => 'close_collection'
  get  'collections/list_all'  => 'hydrus_collections#list_all', :as => 'list_all'

  # Actions to advance Items through the Hydrus process.
  post 'items/publish_directly/:id'    => 'hydrus_items#publish_directly',    :as => 'publish_directly_item'
  post 'items/submit_for_approval/:id' => 'hydrus_items#submit_for_approval', :as => 'submit_for_approval_item'
  post 'items/approve/:id'             => 'hydrus_items#approve',             :as => 'approve_item'
  post 'items/disapprove/:id'          => 'hydrus_items#disapprove',          :as => 'disapprove_item'
  post 'items/open_new_version/:id'    => 'hydrus_items#open_new_version',    :as => 'open_new_version_item'
  post 'items/resubmit/:id'            => 'hydrus_items#resubmit',            :as => 'resubmit_item'
  post 'items/send_purl_email'         => 'hydrus_items#send_purl_email',     :as => 'send_purl_email'
  get  'items/discard_confirmation/:id'       => 'hydrus_items#discard_confirmation',       :as => 'discard_item_confirmation'
  get  'collections/discard_confirmation/:id' => 'hydrus_collections#discard_confirmation', :as => 'discard_collection_confirmation'

  resources :collections, controller: 'hydrus_collections', as: 'hydrus_collections' do
    resources :events, only: :index
    resources :datastreams, only: :index
    resources :items, only: :index, controller: 'hydrus_items'
  end

  resources :items, controller: 'hydrus_items', as: 'hydrus_items' do
    resources :events, only: :index
    resources :datastreams, only: :index
    get 'terms_of_deposit', as: 'terms_of_deposit', on: :collection
    get 'agree_to_terms_of_deposit', as: 'agree_to_terms_of_deposit', on: :collection
  end

  resources :admin_policy_objects, controller: 'hydrus_admin_policy_objects', as: 'hydrus_admin_policy_objects' do
    resources :datastreams, only: :index
  end

  get 'items/:id/destroy_value' => 'hydrus_items#destroy_value', :as => 'destroy_hydrus_item_value'
  post 'items/:id/create_file' => 'hydrus_items#create_file', :as => 'create_hydrus_item_file'
  get 'items/:id/destroy_file' => 'hydrus_items#destroy_file', :as => 'destroy_hydrus_item_file'
  get 'collections/:id/destroy_value' => 'hydrus_collections#destroy_value', :as => 'destroy_hydrus_collection_value'
  devise_scope :user do
    get 'users/auth/webauth' => 'sessions#new', :as => 'webauth_login'
    get 'users/auth/webauth/logout' => 'sessions#destroy_webauth', :as => 'webauth_logout'
  end
  get 'error' => 'signin#error', :as => 'error'
  get 'contact' => 'application#contact', :as=>'contact'

  # Actions for the HydrusSolrController.
  get 'hydrus_solr/reindex/:id'           => 'hydrus_solr#reindex' # NOTE: It's not clear that anything is using this.
  get 'hydrus_solr/delete_from_index/:id' => 'hydrus_solr#delete_from_index' # NOTE: It's not clear that anything is using this.
  match 'dor/reindex/:id'           => 'hydrus_solr#reindex',           :as => 'reindex',           via: [:get, :post, :put]
  match 'dor/delete_from_index/:id' => 'hydrus_solr#delete_from_index', :as => 'delete_from_index', via: [:get, :post]


   get '/404', to: 'exceptions#render_404'
   get '/500', to: 'exceptions#render_500'
end
