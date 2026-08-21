Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#grocery"
  get "grocery", to: "dashboard#grocery", as: :grocery
  get "checklist", to: "dashboard#checklist", as: :checklist
  get "quantities", to: "dashboard#quantities", as: :quantities
  get "bills", to: "dashboard#bills", as: :bills

  post "groceries/import", to: "groceries#import", as: :import_groceries
  get "groceries/sample", to: "groceries#sample", as: :grocery_sample
  post "groceries", to: "groceries#create", as: :groceries
  patch "groceries/:id", to: "groceries#update", as: :grocery_item
  post "groceries/:id/issue", to: "groceries#issue", as: :issue_grocery_item
  delete "groceries/:id", to: "groceries#destroy"
  patch "checklists/bulk", to: "checklists#bulk_update", as: :bulk_checklist
  patch "checklists/:id", to: "checklists#update", as: :checklist_entry
  post "quantities/import", to: "quantities#import", as: :import_quantities
  get "quantities/sample", to: "quantities#sample", as: :quantity_sample
  post "quantities/expense", to: "quantities#add_expense", as: :add_quantity_expense

  get "exports/grocery", to: "exports#grocery", as: :export_grocery
  get "exports/checklist", to: "exports#checklist", as: :export_checklist
  get "exports/quantities", to: "exports#quantities", as: :export_quantities
  get "bills/tables/:id", to: "bills#show", as: :bill
  post "bills/tables/:id/items", to: "bills#add_item", as: :add_bill_item
  patch "bills/:id/items/:line_item_id", to: "bills#update_item", as: :update_bill_item
  delete "bills/:id/items/:line_item_id", to: "bills#remove_item", as: :remove_bill_item
  post "bills/:id/pay", to: "bills#pay", as: :pay_bill
  delete "bills/:id", to: "bills#destroy", as: :delete_bill
  get "bills/:id/pdf", to: "bills#pdf", as: :bill_pdf
  get "bills/:id/print", to: "bills#print", as: :bill_print
end
