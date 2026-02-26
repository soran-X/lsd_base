# Allow SVG files to be served inline (used for logo and favicon uploads).
# These are admin-only uploads in a trusted context, so SVG XSS risk is acceptable.
Rails.application.config.active_storage.content_types_to_serve_as_binary -= [ "image/svg+xml" ]
Rails.application.config.active_storage.content_types_allowed_inline += [ "image/svg+xml" ]
