Reports::Engine.routes.draw do
	root "constructor#show"
	resources :constructor, only: %i[show] do
		collection do
			get :attributes
			get :nested_attributes
			get :nested_associations
		end
	end
end
