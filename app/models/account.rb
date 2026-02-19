class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :purchase_orders, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :integrations, dependent: :destroy

  validates :name, presence: true
end
