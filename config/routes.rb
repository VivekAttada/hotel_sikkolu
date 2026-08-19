Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  post "groceries/import", to: "groceries#import", as: :import_groceries
  patch "checklists/:id", to: "checklists#update", as: :checklist_entry
  post "quantities/import", to: "quantities#import", as: :import_quantities
  post "quantities/expense", to: "quantities#add_expense", as: :add_quantity_expense

  get "exports/grocery", to: "exports#grocery", as: :export_grocery
  get "exports/checklist", to: "exports#checklist", as: :export_checklist
  get "exports/quantities", to: "exports#quantities", as: :export_quantities
  get "exports/team_members", to: "exports#team_members", as: :export_team_members
end
