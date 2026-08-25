class UpdateDiningTablesToRoomLayout < ActiveRecord::Migration[8.1]
  TABLE_NAMES = %w[R1 R2 R3 R4 M1 M2 L1 L2 L3 L4].freeze

  def up
    TABLE_NAMES.each_with_index do |name, index|
      table = DiningTable.find_or_initialize_by(name: name)
      table.position = index + 1
      table.active = true
      table.save!
    end

    DiningTable.where.not(name: TABLE_NAMES).find_each do |table|
      table.update!(active: false, position: table.position + 100)
    end
  end

  def down
    %w[A1 A2 A3 A4 A5 A6].each_with_index do |name, index|
      table = DiningTable.find_or_initialize_by(name: name)
      table.position = index + 1
      table.active = true
      table.save!
    end

    DiningTable.where(name: TABLE_NAMES).update_all(active: false)
  end
end
