Perf::Engine.routes.draw do
  root "main#index"

  resources :main do
    collection do
      get :research_areas
      get :experienced_users
      get :packages
    end
  end

  # resources :digest, only: [] do
  #   collection do
  #     get :run_time
  #   end
  # end

  namespace :admin do
    resources :experts do

    end
  end

end
