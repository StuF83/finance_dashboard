Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Root route - Dashboard
  root "finances#index"

  # ===========================================
  # FINANCES (Dashboard & Analysis)
  # ===========================================
  resources :finances, only: [:index] do
    collection do
      get :categories           # Category breakdown page
      get :category_details     # AJAX endpoint for detailed view
      post :import         # CSV import functionality
    end
  end

  # ===========================================
  # TRANSACTIONS (CRUD Operations)
  # ===========================================
  resources :transactions, only: [:index, :destroy] do
    collection do
      delete :bulk_destroy      # Bulk delete transactions
    end
  end

  # Legacy import route (consider deprecating)
  # post "transactions/import", to: "finances#import", as: "transactions_import"

  # ===========================================
  # PWA ROUTES (Currently disabled)
  # ===========================================
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
