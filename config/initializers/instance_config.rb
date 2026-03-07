# frozen_string_literal: true

# Eagerly load and validate the field configuration at boot time so that a
# bad fields.yml raises immediately rather than silently failing at runtime.
# Must run after_initialize so Zeitwerk has autoloaded app/services/instance_config.rb.
Rails.application.config.after_initialize do
  begin
    InstanceConfig.fields
    Rails.logger.info "[InstanceConfig] Loaded #{InstanceConfig.field_keys.size} fields " \
                      "from #{InstanceConfig.config_path}"
  rescue => e
    raise "InstanceConfig boot error: #{e.message}"
  end
end
