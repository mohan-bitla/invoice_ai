class PurchaseOrder < ApplicationRecord
  belongs_to :account
  has_many :invoices

  validates :po_number, presence: true, uniqueness: true
end
