class User < ApplicationRecord
  belongs_to :account

  validates :role, inclusion: { in: %w[owner bookkeeper viewer] }
end
