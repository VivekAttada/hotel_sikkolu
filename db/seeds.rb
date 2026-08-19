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
team_data = [
  {
    name: "Bindu",
    position: 1,
    description: "Bindu oversees daily hotel operations and ensures every guest experience meets Hotel Sikkolu standards. She coordinates the team and manages supplier relationships."
  },
  {
    name: "Harish",
    position: 2,
    description: "Harish handles inventory and grocery management. He uploads daily stock sheets, tracks quantities, and makes sure the kitchen is always well supplied."
  },
  {
    name: "Manoj",
    position: 3,
    description: "Manoj leads kitchen operations and menu preparation. He works closely with the checklist team to maintain hygiene and food quality throughout the day."
  },
  {
    name: "Abhishek",
    position: 4,
    description: "Abhishek manages front-desk operations and guest services. He keeps hotel information up to date and supports the team with daily administrative tasks."
  }
]

team_data.each do |attrs|
  member = TeamMember.find_or_create_by!(name: attrs[:name]) do |m|
    m.position = attrs[:position]
    m.description = attrs[:description]
  end
  member.update!(position: attrs[:position], description: attrs[:description])

  photo_file = Rails.root.join("db/seed_assets/#{attrs[:name].downcase}.svg")
  if photo_file.exist? && !member.photo.attached?
    member.photo.attach(
      io: File.open(photo_file),
      filename: "#{attrs[:name].downcase}.svg",
      content_type: "image/svg+xml"
    )
  end
end

puts "Seed complete!"
