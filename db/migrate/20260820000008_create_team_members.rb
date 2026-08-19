class CreateTeamMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :team_members do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :team_members, :position
  end
end
