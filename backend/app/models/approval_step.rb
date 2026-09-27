class ApprovalStep < ApplicationRecord
  belongs_to :expense
  belongs_to :decided_by, class_name: "User", optional: true
  enum :stage, { manager: 0, finance: 1 }
  enum :decision, { pending: 0, approved: 1, rejected: 2 }
end
