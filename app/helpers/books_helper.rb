module BooksHelper
  STATUS_BADGE_CLASSES = {
    "draft"    => "bg-gray-100 text-gray-600",
    "active"   => "bg-green-100 text-green-700",
    "inactive" => "bg-yellow-100 text-yellow-700",
    "acquired" => "bg-blue-100 text-blue-700",
    "passed"   => "bg-red-100 text-red-600"
  }.freeze

  def book_status_badge_classes(status)
    STATUS_BADGE_CLASSES.fetch(status.to_s, "bg-gray-100 text-gray-600")
  end
end
