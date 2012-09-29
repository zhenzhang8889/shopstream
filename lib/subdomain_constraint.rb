class SubdomainConstraint
  def initialize(subdomain = :any)
    @subdomain = subdomain
  end

  def matches?(request)
    if @subdomain == :any
      subdomain(request).present?
    else
      subdomain(request) == @subdomain
    end
  end

  def subdomain(request)
    (request.host == ENV['APP_HOST']) ? nil : request.subdomains.first
  end
end
