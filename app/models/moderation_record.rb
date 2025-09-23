class ModerationRecord < ApplicationRecord
  belongs_to :article
  belongs_to :admin, class_name: "User"
  enum :status, { hidden: 0, pending_review: 1, approved: 2, rejected: 3 }
end
