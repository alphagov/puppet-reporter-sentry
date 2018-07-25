require 'puppet'

begin
  require 'sentry-raven'
rescue LoadError => e
  Puppet.err "Install the sentry-raven gem on the Puppetmaster to send reports to Sentry"
end

Puppet::Reports.register_report(:sentry) do
  desc 'Puppet reporter to send failed runs to Sentry'

  sentry_dsn = nil

  if Puppet.settings[:confdir].is_a?(String)
    sentry_conffile = File.join(Puppet.settings[:confdir], 'sentry.conf')
    if Puppet::FileSystem.exist?(sentry_conffile)
      File.readlines(sentry_conffile).each do |conf_line|
        conf_line.chomp!
        key, value = conf_line.split(/\s*=\s*/)
        case key
        when 'dsn'
          sentry_dsn = URI.parse(value)
        end
      end
    end
  end

  if ENV['PUPPET_SENTRY_DSN']
    sentry_dsn = URI.parse(ENV['PUPPET_SENTRY_DSN'])
  end

  if sentry_dsn.nil?
    Puppet.err "Not registering Sentry report processor as DSN is not available"
  else
    sentry_dsn_redacted = sentry_dsn.clone
    sentry_dsn_redacted.user = '***'
    sentry_dsn_redacted.password = '***'

    Puppet.info("Registering Sentry report processor; DSN is #{sentry_dsn_redacted.to_s}")

    Raven.configure do |config|
      config.dsn = sentry_dsn.to_s
    end

    def process
      return unless self.status == 'failed'

      unwanted_log_levels = [:debug, :info, :notice]
      self.logs.reject! { |log_line| unwanted_log_levels.include? log_line.level }

      message = "Puppet run failed on #{self.host}\n" + self.logs.map { |log| log.message }.join("\n\n")

      Raven.capture_message(message, {
        :server_name => self.host,
        :tags => {
          'kind' => self.kind,
          'version' => self.puppet_version,
        },
      })
    end
  end
end
