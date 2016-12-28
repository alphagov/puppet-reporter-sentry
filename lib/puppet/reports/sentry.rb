require 'puppet'

begin
  require 'sentry-raven'
rescue LoadError => e
  Puppet.err "Install the sentry-raven gem on the Puppetmaster to send reports to Sentry"
end

Puppet::Reports.register_report(:sentry) do
  desc 'Puppet reporter to send failed runs to Sentry'

  def process
    return unless self.status == 'failed'

    sentry_dsn = ENV['PUPPET_SENTRY_DSN']

    if not sentry_dsn
      raise(Puppet::ParseError, 'Sentry DSN not available')
    end

    Raven.configure do |config|
      config.dsn = sentry_dsn
    end

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
