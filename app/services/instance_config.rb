# frozen_string_literal: true

# InstanceConfig — single source of truth for which book fields are available
# in this deployment, what they are called, and how they behave.
#
# Load order:
#   1. config/fields.yml        (instance-specific override, if present)
#   2. config/fields.default.yml (fallback — all fields enabled)
#
# Usage:
#   InstanceConfig.enabled?("title")          # => true / false
#   InstanceConfig.label("agency")            # => "Literary Agency" (or override)
#   InstanceConfig.required?("title")         # => true
#   InstanceConfig.searchable?("synopsis")    # => true
#   InstanceConfig.field_keys                 # => ["title", "subtitle", ...]
#   InstanceConfig.field_groups               # => [["Basic Info", ["title", ...]], ...]
#   InstanceConfig.available_report_fields    # => { "title" => "Title", ... }
#
# Reload in development:  InstanceConfig.reload!

class InstanceConfig
  CUSTOM_PATH  = Rails.root.join("config", "fields.yml")
  DEFAULT_PATH = Rails.root.join("config", "fields.default.yml")

  # System-level fallbacks for each recognised field key.
  # Applied when a field is listed in the YAML but omits a property.
  FIELD_DEFAULTS = {
    "title"              => { label: "Title",              required: true  },
    "subtitle"           => { label: "Subtitle",           required: false },
    "old_title"          => { label: "Old Title",          required: false },
    "status"             => { label: "Status",             required: false },
    "publication_year"   => { label: "Publication Year",   required: false },
    "publication_season" => { label: "Publication Season", required: false },
    "genres"             => { label: "Genres",             required: false },
    "sub_genres"         => { label: "Sub-Genres",         required: false },
    "lead_title"         => { label: "Lead Title",         required: false },
    "update_tagline"     => { label: "Update Tagline",     required: false },
    "publisher"          => { label: "Publisher",          required: false },
    "agency"             => { label: "Literary Agency",    required: false },
    "agents"             => { label: "Literary Agent(s)",  required: false },
    "film_agency"        => { label: "Film Agency",        required: false },
    "film_agents"        => { label: "Film Agent(s)",      required: false },
    "subagents"          => { label: "Subagents",          required: false },
    "synopsis"           => { label: "Synopsis",           required: false },
    "log_line"           => { label: "Log Line",           required: false },
    "pub_info"           => { label: "Pub Info",           required: false },
    "material"           => { label: "Material",           required: false },
    "rights_sold"        => { label: "Rights Sold",        required: false },
    "primary_scout"      => { label: "Primary Scout",      required: false },
    "secondary_scout"    => { label: "Secondary Scout",    required: false },
    "film_flag"          => { label: "Film Flag",          required: false },
    "film_synopsis"      => { label: "Film Synopsis",      required: false },
    "film_option"        => { label: "Film Option",        required: false },
    "readers_thoughts"   => { label: "Reader's Thoughts",  required: false },
    "film_genre"         => { label: "Film Genre",         required: false },
    "pages"              => { label: "Pages",              required: false },
    "format"             => { label: "Format",             required: false },
  }.freeze

  KNOWN_KEYS = FIELD_DEFAULTS.keys.freeze

  KNOWN_TABS = %w[info contacts_rights notes coverage film report].freeze

  class << self
    # All enabled fields in definition order.
    # Each element: { key:, group:, label:, required:, searchable: }
    def fields
      @fields ||= build_fields
    end

    # Ordered list of enabled field keys.
    def field_keys
      fields.map { |f| f[:key] }
    end

    # Display label for a key, respecting any YAML override.
    def label(key)
      field_map[key.to_s]&.fetch(:label) ||
        FIELD_DEFAULTS.dig(key.to_s, :label) ||
        key.to_s.humanize
    end

    # Is this field present in the active YAML?
    def enabled?(key)
      field_map.key?(key.to_s)
    end

    # Should the book form treat this field as required?
    def required?(key)
      field_map[key.to_s]&.fetch(:required, false) || false
    end

    # Should search result cards display this field?
    def searchable?(key)
      field_map[key.to_s]&.fetch(:searchable, true) != false
    end

    # All enabled field keys where searchable: true.
    def searchable_keys
      fields.select { |f| f[:searchable] }.map { |f| f[:key] }
    end

    # All enabled field keys where required: true.
    def required_keys
      fields.select { |f| f[:required] }.map { |f| f[:key] }
    end

    # CustomReportTemplate::AVAILABLE_FIELDS-compatible hash.
    # { "key" => "Label" } for every enabled field, in definition order.
    def available_report_fields
      fields.each_with_object({}) { |f, h| h[f[:key]] = f[:label] }
    end

    # CustomReportTemplate::FIELD_GROUPS-compatible array.
    # [["Group Name", ["key1", "key2"]], ...]  — empty groups omitted.
    def field_groups
      raw_config["field_groups"].filter_map do |group|
        name = group["name"]
        keys = (group["fields"] || {}).keys.select { |k| enabled?(k) }
        [name, keys] unless keys.empty?
      end
    end

    # Is this book tab visible? Defaults to true if not listed in YAML.
    def tab_enabled?(key)
      tabs = raw_config["tabs"]
      return true if tabs.nil?
      tabs.fetch(key.to_s, true) != false
    end

    # Path of the config file currently in use.
    def config_path
      CUSTOM_PATH.exist? ? CUSTOM_PATH : DEFAULT_PATH
    end

    # Call in development after editing the YAML without restarting.
    def reload!
      @fields     = nil
      @field_map  = nil
      @raw_config = nil
    end

    private

    def raw_config
      @raw_config ||= begin
        raw = YAML.load_file(config_path)
        validate!(raw)
        raw
      end
    end

    def field_map
      @field_map ||= fields.index_by { |f| f[:key] }
    end

    def build_fields
      result = []
      raw_config["field_groups"].each do |group|
        group_name = group["name"]
        (group["fields"] || {}).each do |key, overrides|
          next unless KNOWN_KEYS.include?(key)
          defaults  = FIELD_DEFAULTS[key]
          overrides = overrides.to_h  # handles nil (field listed with no properties)

          result << {
            key:        key,
            group:      group_name,
            label:      overrides["label"]    || defaults[:label],
            required:   overrides.key?("required")    ? !!overrides["required"]    : defaults[:required],
            searchable: overrides.key?("searchable")   ? !!overrides["searchable"]   : true,
          }
        end
      end
      result
    end

    def validate!(config)
      unless config.is_a?(Hash) && config["field_groups"].is_a?(Array)
        raise ArgumentError,
          "#{config_path}: must be a YAML hash with a 'field_groups' array at the top level."
      end

      config["field_groups"].each_with_index do |group, i|
        unless group.is_a?(Hash) && group["name"].present?
          raise ArgumentError,
            "#{config_path}: field_groups[#{i}] must have a 'name' key."
        end

        (group["fields"] || {}).each_key do |key|
          unless KNOWN_KEYS.include?(key)
            raise ArgumentError,
              "#{config_path}: unknown field '#{key}' in group '#{group["name"]}'.\n" \
              "Known fields: #{KNOWN_KEYS.join(', ')}"
          end
        end
      end

      (config["tabs"] || {}).each_key do |key|
        unless KNOWN_TABS.include?(key)
          raise ArgumentError,
            "#{config_path}: unknown tab '#{key}' in tabs section.\n" \
            "Known tabs: #{KNOWN_TABS.join(', ')}"
        end
      end
    end
  end
end
