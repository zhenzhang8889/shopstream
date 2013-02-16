class RequestEvent
  include Analyzing::Event

  event_for :shop

  data do
    field :resource, type: String
    field :referrer, type: String, default: ''
    field :title, type: String
    field :user_agent, type: String
    field :client_id, type: String

    field :referrer_host, type: String
    field :search_query, type: String

    validates :client_id, presence: true

    before_create :escape_urls, :set_referrer_host, :set_search_query

    def escape_urls
      self.resource = URI.escape(resource) if resource
      self.referrer = URI.escape(referrer)
    end

    def set_referrer_host
      self.referrer_host = URI(referrer).host
    end

    def set_search_query
      self.search_query = CGI.parse(URI(referrer).query || '')['q'].try(:first)
    end
  end

  def self.sample_request(shop, time)
    e = shop.track_request(
      resource: 'http://something.com' + ['/', '/about', '/products', '/cart', "/products/#{(1..99).to_a.sample}"].sample,
       referrer: [
         "https://www.google.com/search?q=#{(('a'..'z').to_a * 3).shuffle.take(3).join}",
         'http://news.ycombinator.com' + ['/', '/news', '/newest', '/ask', "/item?id=#{(5083300..5083390).to_a.sample}"].sample,
         'http://edition.cnn.com',
         'https://www.facebook.com' + ['/', '/messages', "/groups/#{(('a'..'z').to_a * 3).shuffle.take(3).join}"].sample
       ].sample,
       title: (('a'..'z').to_a * 3).shuffle.take(3).join,
       user_agent: [
         'Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.13+ (KHTML, like Gecko) Version/5.1.7 Safari/534.57.2',
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1309.0 Safari/537.17',
         'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.15 (KHTML, like Gecko) Chrome/24.0.1295.0 Safari/537.15',
         'Mozilla/5.0 (Windows NT 6.2) AppleWebKit/537.4 (KHTML, like Gecko) Chrome/22.0.1229.94 Safari/537.4',
         'Mozilla/6.0 (Windows NT 6.2; WOW64; rv:16.0.1) Gecko/20121011 Firefox/16.0.1',
         'Mozilla/5.0 (Windows NT 6.1; rv:15.0) Gecko/20120716 Firefox/15.0a2',
         'Mozilla/5.0 (compatible; MSIE 10.6; Windows NT 6.1; Trident/5.0; InfoPath.2; SLCC1; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; .NET CLR 2.0.50727) 3gpp-gba UNTRUSTED/1.0',
         'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)',
         'Mozilla/5.0 (Windows; U; MSIE 9.0; WIndows NT 9.0; en-US))'
      ].sample,
      client_id: (('a'..'z').to_a * 20).shuffle.take(16)
    )
    e.created_at = time.is_a?(Range) ? rand(time) : time
    e.save
  end
end
