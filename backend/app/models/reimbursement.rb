class Reimbursement < ApplicationRecord
  belongs_to :expense
  enum :status, { requested: 0, processing: 1, paid: 2, failed: 3 }
end
