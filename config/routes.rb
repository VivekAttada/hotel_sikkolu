Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#home"
  get "grocery", to: "dashboard#grocery", as: :grocery
  get "checklist", to: "dashboard#checklist", as: :checklist
  get "bills", to: "dashboard#bills", as: :bills
  get "paid_bills", to: "dashboard#paid_bills", as: :paid_bills
  get "bill_edits", to: "dashboard#bill_edits", as: :bill_edits
  get "payments", to: "dashboard#payments", as: :payments
  get "settings", to: "dashboard#settings", as: :settings
  patch "settings", to: "settings#update"
  post "settings/email_report", to: "settings#send_email_report", as: :settings_email_report
  get "takeaway", to: "dashboard#takeaway", as: :takeaway
  post "takeaway/orders", to: "takeaways#create", as: :takeaway_orders

  post "groceries/import", to: "groceries#import", as: :import_groceries
  get "groceries/sample", to: "groceries#sample", as: :grocery_sample
  post "groceries", to: "groceries#create", as: :groceries
  patch "groceries/:id", to: "groceries#update", as: :grocery_item
  post "groceries/:id/issue", to: "groceries#issue", as: :issue_grocery_item
  delete "groceries/:id", to: "groceries#destroy"
  patch "checklists/bulk", to: "checklists#bulk_update", as: :bulk_checklist
  patch "checklists/:id", to: "checklists#update", as: :checklist_entry
  post "checklists/:id/photo", to: "checklists#upload_photo", as: :checklist_entry_photo
  delete "checklists/:id/photo", to: "checklists#destroy_photo", as: :destroy_checklist_entry_photo

  get "exports/grocery", to: "exports#grocery", as: :export_grocery
  get "exports/checklist", to: "exports#checklist", as: :export_checklist
  get "bills/tables/:id", to: "bills#show", as: :bill
  post "bills/tables/:id/items", to: "bills#add_item", as: :add_bill_item
  post "dining_tables/:id/split", to: "dining_tables#split", as: :split_dining_table
  post "dining_tables/:id/merge", to: "dining_tables#merge", as: :merge_dining_table
  patch "bills/:id/items/:line_item_id", to: "bills#update_item", as: :update_bill_item
  delete "bills/:id/items/:line_item_id", to: "bills#remove_item", as: :remove_bill_item
  post "bills/:id/pay", to: "bills#pay", as: :pay_bill
  post "bills/:id/void", to: "bills#void", as: :void_bill
  post "bills/:id/restore", to: "bills#restore", as: :restore_bill
  patch "bills/:id/guest", to: "bills#guest", as: :bill_guest
  delete "bills/:id", to: "bills#destroy", as: :delete_bill
  get "bills/:id/pdf", to: "bills#pdf", as: :bill_pdf
  get "bills/:id/print", to: "bills#print", as: :bill_print
  post "bills/:id/kot", to: "bills#kot", as: :bill_kot
end
