Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  post "v1/intake", to: "intakes#create"
  match "v1/intake", to: "intakes#preflight", via: :options
end
