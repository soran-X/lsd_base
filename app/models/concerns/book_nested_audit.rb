# Concern added to models that belong to Book and should trigger
# an audit log entry when they are created/updated/destroyed.
#
# It writes a book-scoped "update" record with metadata containing a
# single change keyed by the association name.  The value for the change
# is an array of [before, after] strings; this conveniently fits the
# rendering logic already used in the book show page.
module BookNestedAudit
  extend ActiveSupport::Concern

  included do
    after_create  :audit_book_child_create
    after_update  :audit_book_child_update
    after_destroy :audit_book_child_destroy

    # make sure the parent book is eager loaded so callback can access it
    belongs_to :book
  end

  private

    def audit_book_child_create
      return unless book
      summary = audit_child_summary
      record_audit("+ #{summary}")
    end

    def audit_book_child_update
      return unless book
      # ignore trivial timestamp-only updates
      dirty = saved_changes.except("updated_at", "created_at", "book_id")
      return if dirty.empty?

      details = dirty.map { |k, v|
        before, after = v
        # strip HTML for text fields such as notes or material
        if %w[note material content].include?(k)
          before = strip_to_plain(before)
          after  = strip_to_plain(after)
        end
        "#{k}: #{before.inspect} → #{after.inspect}"
      }.join("; ")

      record_audit("~ #{details}")
    end

    def audit_book_child_destroy
      return unless book
      summary = audit_child_summary
      record_audit("- #{summary}")
    end

    def audit_child_summary
      if respond_to?(:note) && note.present?
        # show first 80 characters of plain-text note
        truncate_plain(note)
      elsif respond_to?(:material) && material.present?
        truncate_plain(material)
      else
        self.class.name
      end
    end

    def truncate_plain(str)
      strip_to_plain(str).truncate(80)
    end

    def strip_to_plain(str)
      ActionController::Base.helpers.strip_tags(str.to_s).squish
    end

    def record_audit(message)
      field = self.class.name.underscore.pluralize
      changes_hash = { field => ["", message] }
      AuditLog.record(user: Current.user, action: "update", resource: book,
                      metadata: { changes: changes_hash })
    end
end
