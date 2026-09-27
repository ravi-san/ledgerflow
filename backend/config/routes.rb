Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  post "/auth/login", to: "auth#login"
  resources :teams, only: [:index, :show, :create, :update] do
    member { post :join }
    resources :memberships, only: [:index, :update, :destroy]
    resources :expenses, only: [:index, :create]
    resources :imports, only: [:index, :create]
  end
  resources :expenses, only: [:show, :update, :destroy] do
    member do
      get :audit_trail
      get :compare
      post :submit
      post :approve
      post :reject
      post :reimburse
      post :process_reimbursement
      post :pay_reimbursement
    end
  end
  resources :imports, only: [:show] do
    member { post :accept; post :reject }
    collection { post :bulk_accept; post :bulk_reject }
  end
end
