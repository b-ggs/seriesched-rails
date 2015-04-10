Rails.application.routes.draw do
  root 'application#index'

  get 'home' => 'application#home'
  get 'browse' => 'application#browse'
  get 'collection' => 'application#collection'
  get 'episodedetails' => 'application#episodedetails'
  get 'profile' => 'application#profile'
  get 'schedule' => 'application#schedule'
  get 'search' => 'application#search'
  get 'showdetails' => 'application#showdetails'

  post 'signup' => 'application#signup'
  post 'login' => 'application#login'
  post 'logout' => 'application#logout'
  post 'search_action' => 'application#search_action'
  post 'showdetails_init' => 'application#showdetails_init'
  post 'showdetails_add' => 'application#showdetails_add'
  post 'showdetails_remove' => 'application#showdetails_remove'
  post 'episodedetails_init' => 'application#episodedetails_init'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
