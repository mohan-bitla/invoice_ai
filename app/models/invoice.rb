class Invoice < ApplicationRecord
  belongs_to :account
  belongs_to :po, class_name: 'PurchaseOrder', optional: true
  has_many :invoice_lines, dependent: :destroy
  has_one :extraction, dependent: :destroy

  enum :status, { uploaded: 'uploaded', extracting: 'extracting', extracted: 'extracted', matched: 'matched', approved: 'approved', exported: 'exported', error: 'error' }
end
