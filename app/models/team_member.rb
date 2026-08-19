class TeamMember < ApplicationRecord
  has_one_attached :photo

  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }
end
