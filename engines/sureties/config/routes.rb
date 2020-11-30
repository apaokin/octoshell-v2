Sureties::Engine.routes.draw do
  namespace :admin do
    resources :sureties do
      collection do
        post :find
        get :template,     action: :edit_template
        put :template,     action: :update_template
        put :default,      action: :default_template
        put :rtf_template
        put :default_rtf
        get :rtf_template, action: :download_rtf_template
      end
      put :activate
      put :close
      put :confirm
      put :reject
      put :activate_or_reject
    end

    resources :sureties do
      get :confirm, on: :member
      get :close, on: :member
    end
  end
  resources :sureties do
    get :confirm, on: :member
    get :close, on: :member
  end

end
