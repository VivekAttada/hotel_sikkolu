class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable,
         authentication_keys: [ :username ]

  validates :username, presence: true, uniqueness: { case_sensitive: false }

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:username) || conditions.delete(:login)
    where(conditions).where([ "lower(username) = :value", { value: login.to_s.downcase.strip } ]).first
  end
end
