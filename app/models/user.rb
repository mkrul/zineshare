class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :zines, dependent: :destroy

  scope :admins, -> { where(admin: true) }

  def admin?
    admin
  end
end
