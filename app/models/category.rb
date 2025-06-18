class Category < ApplicationRecord
  has_many :zines, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
