class Project::RemoteURL
  require 'open-uri'

  def self.load(remote_project, path)
    uri = URI.parse(remote_project.remoteurl + path)
    # prefer environment variables if set
    if ENV['http_proxy'].blank?
      ENV['http_proxy'] = Configuration.first.http_proxy
    end
    if ENV['https_proxy'].blank?
      ENV['https_proxy'] = Configuration.first.http_proxy
    end
    if ENV['no_proxy'].blank?
      ENV['no_proxy'] = Configuration.first.no_proxy
    end
    begin
      uri.open.read
    rescue OpenURI::HTTPError, SocketError, Errno::EINTR, Errno::EPIPE, EOFError, Net::HTTPBadResponse, IOError, Errno::ENETUNREACH,
           Errno::ETIMEDOUT, Errno::ECONNREFUSED, Timeout::Error, OpenSSL::SSL::SSLError => e
      Rails.logger.debug "#{e} when fetching #{path} from #{remote_project.remoteurl}"
      nil
    end
  end
end
