# Hotel Sikkolu seed data

puts "Seeding checklist tasks..."

checklist_tasks = [
  # Daily
  { title: "Glasses — Front door to Back (need to be clean always)", frequency: "daily", position: 1 },
  { title: "Tandoori Area — ceiling", frequency: "daily", position: 2 },
  { title: "Bill Counter", frequency: "daily", position: 3 },
  { title: "Floor", frequency: "daily", position: 4 },
  { title: "Tables & chairs", frequency: "daily", position: 5 },
  { title: "Kitchen", frequency: "daily", position: 6 },
  { title: "Washroom cleaning & working conditions", frequency: "daily", position: 7 },
  { title: "Waiters to be ready by 11:30 am (with uniform, caps), chefs", frequency: "daily", position: 8 },

  # Weekly
  { title: "Fans cleaning", frequency: "weekly", position: 1 },
  { title: "Kitchen deep cleaning", frequency: "weekly", position: 2 },
  { title: "Sitting area ceiling", frequency: "weekly", position: 3 },
  { title: "Fridge cleaning — inside kitchen", frequency: "weekly", position: 4 },
  { title: "Repairs (Gas, Washroom, Electrical)", frequency: "weekly", position: 5 },
  { title: "Plates counting (Cutlery & culinary)", frequency: "weekly", position: 6 },
  { title: "Lighting board cleaning", frequency: "weekly", position: 7 },
  { title: "Floor deep cleaning", frequency: "weekly", position: 8 },
  { title: "Outside Fridge cleaning (Cleanjoy)", frequency: "weekly", position: 9 },

  # Monthly
  { title: "Pest Control", frequency: "monthly", position: 1 }
]

seed_titles = checklist_tasks.map { |t| t[:title] }

checklist_tasks.each do |attrs|
  task = ChecklistTask.find_or_initialize_by(title: attrs[:title])
  task.assign_attributes(frequency: attrs[:frequency], position: attrs[:position], active: true)
  task.save!
end

ChecklistTask.where.not(title: seed_titles).update_all(active: false)

puts "Seeding team members..."
# Rename legacy names if present
TeamMember.where(name: "Bindu").find_each { |m| m.update!(name: "Bindu/Hareesh") }
TeamMember.where(name: "Harish").find_each { |m| m.update!(name: "Somnath") }

team_data = [
  {
    name: "Bindu/Hareesh",
    position: 1,
    photo_key: "bindu",
    description: "Bindu/Hareesh oversee daily hotel operations and ensure every guest experience meets Hotel Sikkolu standards. They coordinate the team and manage supplier relationships."
  },
  {
    name: "Somnath",
    position: 2,
    photo_key: "somnath",
    description: "Somnath handles inventory and grocery management. He uploads daily stock sheets, tracks quantities, and makes sure the kitchen is always well supplied."
  },
  {
    name: "Manoj",
    position: 3,
    photo_key: "manoj",
    description: "Manoj leads kitchen operations and menu preparation. He works closely with the checklist team to maintain hygiene and food quality throughout the day."
  },
  {
    name: "Abhishek",
    position: 4,
    photo_key: "abhishek",
    description: "Abhishek manages front-desk operations and guest services. He keeps hotel information up to date and supports the team with daily administrative tasks."
  }
]

team_data.each do |attrs|
  member = TeamMember.find_or_create_by!(name: attrs[:name]) do |m|
    m.position = attrs[:position]
    m.description = attrs[:description]
  end
  member.update!(position: attrs[:position], description: attrs[:description])

  photo_file = Rails.root.join("db/seed_assets/#{attrs[:photo_key]}.svg")
  if photo_file.exist? && !member.photo.attached?
    member.photo.attach(
      io: File.open(photo_file),
      filename: "#{attrs[:photo_key]}.svg",
      content_type: "image/svg+xml"
    )
  end
end

# Remove any leftover old team names
TeamMember.where(name: [ "Bindu", "Harish" ]).destroy_all

puts "Seeding login user..."
User.find_or_create_by!(username: "hotel_sikkolu") do |user|
  user.email = "hotel_sikkolu@sikkolu.local"
  user.password = "hotel_sikkolu@123"
  user.password_confirmation = "hotel_sikkolu@123"
end

puts "Seeding dining tables A1–A6..."
(1..6).each do |n|
  table = DiningTable.find_or_initialize_by(name: "A#{n}")
  table.position = n
  table.active = true
  table.save!
end

puts "Seeding restaurant menu from Hotel Sikkolu client menu..."
menu_items = [
  # Soups
  { name: "Veg Hot & Sour", category: "Soups", price: 120, position: 1 },
  { name: "Veg Manchow", category: "Soups", price: 120, position: 2 },
  { name: "Veg Sweet Corn", category: "Soups", price: 120, position: 3 },
  { name: "Veg Lemon Coriander", category: "Soups", price: 140, position: 4 },
  { name: "Chicken Hot & Sour", category: "Soups", price: 140, position: 5 },
  { name: "Chicken Manchow", category: "Soups", price: 140, position: 6 },
  { name: "Chicken Sweet Corn", category: "Soups", price: 140, position: 7 },
  { name: "Chicken Lemon Coriander", category: "Soups", price: 150, position: 8 },

  # Veg Starters
  { name: "Chilli Paneer", category: "Veg Starters", price: 260, position: 1 },
  { name: "Paneer 65", category: "Veg Starters", price: 260, position: 2 },
  { name: "Paneer Majestic", category: "Veg Starters", price: 290, position: 3 },
  { name: "Paneer Manchurian", category: "Veg Starters", price: 270, position: 4 },
  { name: "Dragon Paneer", category: "Veg Starters", price: 290, position: 5 },
  { name: "Paneer Fingers", category: "Veg Starters", price: 290, position: 6 },
  { name: "Chilli Mushroom", category: "Veg Starters", price: 270, position: 7 },
  { name: "Mushroom Manchurian", category: "Veg Starters", price: 270, position: 8 },
  { name: "Mushroom 65", category: "Veg Starters", price: 270, position: 9 },
  { name: "Pepper Mushroom", category: "Veg Starters", price: 280, position: 10 },
  { name: "Crispy Corn", category: "Veg Starters", price: 190, position: 11 },
  { name: "Gobi 65", category: "Veg Starters", price: 190, position: 12 },
  { name: "Chilli Gobi", category: "Veg Starters", price: 200, position: 13 },
  { name: "Gobi Manchurian", category: "Veg Starters", price: 200, position: 14 },

  # Non-Veg Starters
  { name: "Chicken 65", category: "Non-Veg Starters", price: 260, position: 1 },
  { name: "Chilli Chicken", category: "Non-Veg Starters", price: 260, position: 2 },
  { name: "Chicken Manchurian", category: "Non-Veg Starters", price: 270, position: 3 },
  { name: "Chilli Chicken Wings", category: "Non-Veg Starters", price: 260, position: 4 },
  { name: "Chicken Drumstick", category: "Non-Veg Starters", price: 260, position: 5 },
  { name: "Chicken Lollipop", category: "Non-Veg Starters", price: 260, position: 6 },
  { name: "Dragon Chicken", category: "Non-Veg Starters", price: 280, position: 7 },
  { name: "Chicken Fingers", category: "Non-Veg Starters", price: 300, position: 8 },
  { name: "Hawaiian Chicken", category: "Non-Veg Starters", price: 290, position: 9 },
  { name: "Schezwan Chicken", category: "Non-Veg Starters", price: 290, position: 10 },
  { name: "Lemon Chicken", category: "Non-Veg Starters", price: 290, position: 11 },
  { name: "Cashew Chicken Dry", category: "Non-Veg Starters", price: 320, position: 12 },
  { name: "Chicken Majestic", category: "Non-Veg Starters", price: 310, position: 13 },
  { name: "Pepper Chicken", category: "Non-Veg Starters", price: 290, position: 14 },
  { name: "Chicken 555", category: "Non-Veg Starters", price: 290, position: 15 },
  { name: "Chicken 99", category: "Non-Veg Starters", price: 310, position: 16 },
  { name: "Garlic Chicken", category: "Non-Veg Starters", price: 300, position: 17 },
  { name: "Coriander Chicken", category: "Non-Veg Starters", price: 300, position: 18 },
  { name: "Egg 65", category: "Non-Veg Starters", price: 180, position: 19 },
  { name: "Egg Manchurian", category: "Non-Veg Starters", price: 180, position: 20 },
  { name: "Chilli Egg", category: "Non-Veg Starters", price: 180, position: 21 },
  { name: "Egg Crunch", category: "Non-Veg Starters", price: 250, position: 22 },
  { name: "Mutton Ghee Roast", category: "Non-Veg Starters", price: 390, position: 23 },

  # Seafood Starters
  { name: "Chilli Prawn", category: "Seafood Starters", price: 300, position: 1 },
  { name: "Prawn 65", category: "Seafood Starters", price: 300, position: 2 },
  { name: "Prawn Manchurian", category: "Seafood Starters", price: 300, position: 3 },
  { name: "Loose Prawns", category: "Seafood Starters", price: 320, position: 4 },
  { name: "Butter Garlic Prawn", category: "Seafood Starters", price: 340, position: 5 },
  { name: "Chilli Fish", category: "Seafood Starters", price: 290, position: 6 },
  { name: "Apollo Fish", category: "Seafood Starters", price: 290, position: 7 },
  { name: "Fish 65", category: "Seafood Starters", price: 290, position: 8 },
  { name: "Fish Manchurian", category: "Seafood Starters", price: 290, position: 9 },
  { name: "Fish Fingers", category: "Seafood Starters", price: 320, position: 10 },

  # Tandoori
  { name: "Tandoori Chicken (Full)", category: "Tandoori", price: 520, position: 1 },
  { name: "Tandoori Chicken (Half)", category: "Tandoori", price: 290, position: 2 },
  { name: "Kalmi Kebab", category: "Tandoori", price: 340, position: 3 },
  { name: "Chicken Tikka", category: "Tandoori", price: 340, position: 4 },
  { name: "Lemon Tikka", category: "Tandoori", price: 340, position: 5 },
  { name: "Malai Tikka", category: "Tandoori", price: 340, position: 6 },
  { name: "Sikkolu Special Kebab", category: "Tandoori", price: 400, position: 7 },
  { name: "Fish Tikka", category: "Tandoori", price: 380, position: 8 },
  { name: "Prawn Tikka", category: "Tandoori", price: 390, position: 9 },
  { name: "Paneer Tikka", category: "Tandoori", price: 310, position: 10 },
  { name: "Gobi Tikka", category: "Tandoori", price: 290, position: 11 },

  # Main Course Veg
  { name: "Veg Jaipuri", category: "Main Course Veg", price: 180, position: 1 },
  { name: "Green Peas Masala", category: "Main Course Veg", price: 180, position: 2 },
  { name: "Gobi Masala", category: "Main Course Veg", price: 190, position: 3 },
  { name: "Mixed Veg Curry", category: "Main Course Veg", price: 190, position: 4 },
  { name: "Aloo Gobi Masala", category: "Main Course Veg", price: 200, position: 5 },
  { name: "Paneer Curry", category: "Main Course Veg", price: 240, position: 6 },
  { name: "Paneer Butter Masala", category: "Main Course Veg", price: 250, position: 7 },
  { name: "Methi Chaman", category: "Main Course Veg", price: 260, position: 8 },
  { name: "Palak Paneer", category: "Main Course Veg", price: 260, position: 9 },
  { name: "Paneer Tikka Masala", category: "Main Course Veg", price: 290, position: 10 },
  { name: "Cashew Paneer Curry", category: "Main Course Veg", price: 290, position: 11 },
  { name: "Sikkolu Paneer Curry", category: "Main Course Veg", price: 290, position: 12 },
  { name: "Kadai Paneer", category: "Main Course Veg", price: 250, position: 13 },
  { name: "Mushroom Curry", category: "Main Course Veg", price: 240, position: 14 },
  { name: "Kadai Mushroom", category: "Main Course Veg", price: 250, position: 15 },
  { name: "Mushroom Cashew Masala", category: "Main Course Veg", price: 280, position: 16 },
  { name: "Dal Fry", category: "Main Course Veg", price: 160, position: 17 },
  { name: "Dal Tadka", category: "Main Course Veg", price: 160, position: 18 },
  { name: "Dal Tomato", category: "Main Course Veg", price: 160, position: 19 },

  # Main Course Egg
  { name: "Egg Curry", category: "Main Course Egg", price: 120, position: 1 },
  { name: "Egg Masala", category: "Main Course Egg", price: 140, position: 2 },
  { name: "Egg Bhurji", category: "Main Course Egg", price: 150, position: 3 },
  { name: "Egg Kheema Masala", category: "Main Course Egg", price: 160, position: 4 },
  { name: "Egg Fry", category: "Main Course Egg", price: 150, position: 5 },
  { name: "Egg Tadka", category: "Main Course Egg", price: 160, position: 6 },

  # Main Course Non-Veg
  { name: "Chicken Bone Curry", category: "Main Course Non-Veg", price: 220, position: 1 },
  { name: "Chicken Boneless Curry", category: "Main Course Non-Veg", price: 260, position: 2 },
  { name: "Chicken Fry", category: "Main Course Non-Veg", price: 270, position: 3 },
  { name: "Kadai Chicken", category: "Main Course Non-Veg", price: 260, position: 4 },
  { name: "Chicken Hyderabadi", category: "Main Course Non-Veg", price: 270, position: 5 },
  { name: "Butter Chicken", category: "Main Course Non-Veg", price: 280, position: 6 },
  { name: "Mughlai Chicken", category: "Main Course Non-Veg", price: 280, position: 7 },
  { name: "Chicken Chettinad", category: "Main Course Non-Veg", price: 280, position: 8 },
  { name: "Chicken Kolhapuri", category: "Main Course Non-Veg", price: 290, position: 9 },
  { name: "Chicken Afghani", category: "Main Course Non-Veg", price: 290, position: 10 },
  { name: "Chicken Cashew Curry", category: "Main Course Non-Veg", price: 290, position: 11 },
  { name: "Chicken Tikka Masala", category: "Main Course Non-Veg", price: 300, position: 12 },
  { name: "Chicken Patiala", category: "Main Course Non-Veg", price: 340, position: 13 },
  { name: "Chicken Punjabi Bone", category: "Main Course Non-Veg", price: 350, position: 14 },
  { name: "Sikkolu Special Chicken", category: "Main Course Non-Veg", price: 320, position: 15 },

  # Seafood Curries
  { name: "Fish Curry", category: "Seafood Curries", price: 240, position: 1 },
  { name: "Kadai Fish", category: "Seafood Curries", price: 260, position: 2 },
  { name: "Kadai Prawn", category: "Seafood Curries", price: 280, position: 3 },
  { name: "Prawn Curry", category: "Seafood Curries", price: 300, position: 4 },
  { name: "Sikkolu Prawn Curry", category: "Seafood Curries", price: 350, position: 5 },

  # Main Course Mutton
  { name: "Mutton Curry", category: "Main Course Mutton", price: 350, position: 1 },
  { name: "Kadai Mutton", category: "Main Course Mutton", price: 350, position: 2 },
  { name: "Mutton Masala", category: "Main Course Mutton", price: 370, position: 3 },
  { name: "Mutton Rogan Josh", category: "Main Course Mutton", price: 370, position: 4 },
  { name: "Sikkolu Mutton", category: "Main Course Mutton", price: 390, position: 5 },

  # Biryani
  { name: "Chicken Dum Biryani", category: "Biryani", price: 240, position: 1 },
  { name: "Chicken Fry Biryani", category: "Biryani", price: 260, position: 2 },
  { name: "Lollipop Biryani", category: "Biryani", price: 300, position: 3 },
  { name: "Chicken Mughlai Biryani", category: "Biryani", price: 290, position: 4 },
  { name: "Chicken Tikka Biryani", category: "Biryani", price: 360, position: 5 },
  { name: "Chicken Kalmi Biryani", category: "Biryani", price: 360, position: 6 },
  { name: "Chicken Tandoori Biryani", category: "Biryani", price: 380, position: 7 },
  { name: "Sikkolu Special Biryani", category: "Biryani", price: 390, position: 8 },
  { name: "Mutton Dum Biryani", category: "Biryani", price: 390, position: 9 },
  { name: "Mutton Fry Biryani", category: "Biryani", price: 410, position: 10 },
  { name: "Mutton Ghee Roast Biryani", category: "Biryani", price: 450, position: 11 },
  { name: "Special Prawn Biryani", category: "Biryani", price: 360, position: 12 },
  { name: "Prawn Fry Biryani", category: "Biryani", price: 340, position: 13 },
  { name: "Egg Biryani", category: "Biryani", price: 200, position: 14 },
  { name: "Veg Biryani", category: "Biryani", price: 200, position: 15 },
  { name: "Paneer Biryani", category: "Biryani", price: 240, position: 16 },
  { name: "Cashew Biryani", category: "Biryani", price: 250, position: 17 },
  { name: "Mushroom Biryani", category: "Biryani", price: 230, position: 18 },
  { name: "Biryani Rice", category: "Biryani", price: 120, position: 19 },

  # Rice
  { name: "White Rice", category: "Rice", price: 60, position: 1 },
  { name: "Jeera Rice", category: "Rice", price: 150, position: 2 },
  { name: "Curd Rice", category: "Rice", price: 130, position: 3 },
  { name: "Veg Fried Rice", category: "Rice", price: 180, position: 4 },
  { name: "Veg Schezwan Rice", category: "Rice", price: 190, position: 5 },
  { name: "Paneer Fried Rice", category: "Rice", price: 230, position: 6 },
  { name: "Mushroom Fried Rice", category: "Rice", price: 220, position: 7 },
  { name: "Cashew Fried Rice", category: "Rice", price: 240, position: 8 },
  { name: "Special Veg Fried Rice", category: "Rice", price: 280, position: 9 },
  { name: "Mixed Veg Fried Rice", category: "Rice", price: 260, position: 10 },
  { name: "Egg Fried Rice", category: "Rice", price: 200, position: 11 },
  { name: "Chicken Fried Rice", category: "Rice", price: 240, position: 12 },
  { name: "Spl Chicken Fried Rice", category: "Rice", price: 320, position: 13 },
  { name: "Chicken Schezwan Fried Rice", category: "Rice", price: 260, position: 14 },
  { name: "Mixed Non-Veg Fried Rice", category: "Rice", price: 320, position: 15 },

  # Breads
  { name: "Tandoori Roti", category: "Breads", price: 50, position: 1 },
  { name: "Butter Roti", category: "Breads", price: 60, position: 2 },
  { name: "Naan", category: "Breads", price: 60, position: 3 },
  { name: "Butter Naan", category: "Breads", price: 70, position: 4 },
  { name: "Garlic Butter Naan", category: "Breads", price: 80, position: 5 },

  # Extras
  { name: "Green Salad", category: "Extras", price: 60, position: 1 },
  { name: "Papad", category: "Extras", price: 70, position: 2 },
  { name: "Masala Papad", category: "Extras", price: 70, position: 3 },
  { name: "Plain Curd", category: "Extras", price: 20, position: 4 },

  # Beverages
  { name: "Water Bottle", category: "Beverages", price: 20, position: 1 },
  { name: "Glass Bottle Drink", category: "Beverages", price: 30, position: 2 },
  { name: "Soft Drink (500ml)", category: "Beverages", price: 40, position: 3 },
  { name: "Coke Tin", category: "Beverages", price: 40, position: 4 },
  { name: "Soda", category: "Beverages", price: 30, position: 5 }
]

seed_menu_names = menu_items.map { |item| item[:name] }

menu_items.each do |attrs|
  item = MenuItem.find_or_initialize_by(name: attrs[:name])
  item.assign_attributes(attrs.merge(active: true))
  item.save!
end

MenuItem.where.not(name: seed_menu_names).update_all(active: false)

puts "Menu seeded: #{seed_menu_names.size} active items across #{menu_items.map { |i| i[:category] }.uniq.size} categories."

puts "Seed complete!"
