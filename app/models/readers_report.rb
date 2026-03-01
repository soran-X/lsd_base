class ReadersReport < ApplicationRecord
  include BookNestedAudit

  enum :publishing_recommended, { yes: 0, no: 1, mixed: 2 }, prefix: :pub_rec
  enum :film_recommended,       { yes: 0, no: 1, mixed: 2 }, prefix: :film_rec

  belongs_to :reader, class_name: "User", optional: true
  belongs_to :reading_material, optional: true
end
