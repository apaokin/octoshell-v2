Reports::Engine.routes.draw do
	root "constructor#show"
	resources :constructor, only: %i[show] do
		collection do
			get :class_info
		end
	end
end
