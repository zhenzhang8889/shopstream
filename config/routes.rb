require 'subdomain_constraint'

ShopstreamApi::Application.routes.draw do
  scope constraints: SubdomainConstraint.new('manage') do
    devise_for :superusers

    scope module: 'superuser' do
      resource :dashboard, controller: 'dashboard', only: [:show]

      resources :users, only: [:index, :show] do
        resources :masquerades, only: [:new]
      end

      resources :shops, only: [:index]

      root to: 'users#index'
    end
  end

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    omniauth_callbacks: 'omniauth_callbacks'
  }

  devise_scope :user do
    match '/auth/shopify/callback' => 'omniauth_callbacks#shopify'
  end

  resources :shops, only: [:show] do
    get :connect, on: :collection
  end

  namespace :v1 do
    resources :users, only: [:show] do
      get :me, on: :collection
    end
    resources :shops, only: [:index, :show, :update, :create, :destroy] do
      post :send_instructions, on: :member
    end
  end

  root to: 'home#app'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
