class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :account

  # Allow User model to accept and save attributes for the associated Account model via a single form.
  # The form will use `fields_for` helper to create fields for the nested Account record.
  accepts_nested_attributes_for :account

  has_many :emails, dependent: :destroy

  after_create_commit :generate_alias

  def generate_alias
    email_alias = "#{email.split('@')[0]}-#{id}"
    update_column(:email_alias, email_alias)
  end
end
