class InitialSchema < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto'
    # enable_extension 'vector'

    create_table :accounts, id: :uuid do |t|
      t.string :name, null: false
      t.string :industry
      t.integer :max_invoices, default: 500
      t.timestamps
    end

    create_table :users, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :role, default: 'bookkeeper'
      t.timestamps
    end
    # Removed redundant index on account_id

    create_table :purchase_orders, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :po_number
      t.string :vendor_name
      t.decimal :total_amount, precision: 12, scale: 2
      t.jsonb :expected_items
      t.string :status, default: 'pending'
      t.timestamps
    end
    add_index :purchase_orders, [ :account_id, :vendor_name ], name: 'idx_po_account_vendor'
    add_index :purchase_orders, :po_number, unique: true

    create_table :invoices, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :po, foreign_key: { to_table: :purchase_orders }, type: :uuid
      t.string :file_url
      t.string :invoice_number
      t.string :vendor_name
      t.date :invoice_date
      t.date :due_date
      t.decimal :total_amount, precision: 12, scale: 2
      t.string :currency, default: 'INR'
      t.string :status, default: 'uploaded'
      t.jsonb :extracted_data
      t.decimal :match_confidence, precision: 3, scale: 2
      t.decimal :discrepancy_amount, precision: 12, scale: 2, default: 0
      t.text :notes
      t.datetime :processed_at
      t.timestamps
    end
    add_index :invoices, [ :account_id, :status ], name: 'idx_invoices_account_status'
    add_index :invoices, [ :account_id, :vendor_name, :invoice_date ], name: 'idx_invoices_vendor_date'

    create_table :invoice_lines, id: :uuid do |t|
      t.references :invoice, null: false, foreign_key: true, type: :uuid
      t.text :description
      t.decimal :quantity, precision: 10, scale: 3
      t.decimal :unit_price, precision: 12, scale: 2
      t.decimal :line_total, precision: 12, scale: 2
      t.string :sku
      t.timestamps
    end

    create_table :extractions, id: :uuid do |t|
      t.references :invoice, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.string :ai_model
      t.text :raw_prompt
      t.jsonb :raw_response
      t.decimal :confidence, precision: 3, scale: 2
      t.text :error_message
      t.integer :duration_ms
      t.decimal :cost_usd, precision: 8, scale: 6
      t.string :status, default: 'pending'
      t.timestamps
    end

    create_table :integrations, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :type
      t.jsonb :config
      t.boolean :is_active, default: true
      t.datetime :last_sync
      t.timestamps
    end
  end
end
