#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'puppet'
require 'facter'
require 'fileutils'
require 'net/http'

Puppet.initialize_settings

params            = JSON.parse(STDIN.read)
restore           = params['restore'] || false
target            = params['target']

@fqdn             = Facter.value(:fqdn)

ssldir            = Puppet.settings.value(:ssldir)
private_keysdir   = "#{ssldir}/private_keys"
certsdir          = "#{ssldir}/certs"

@private_keysfile = "#{private_keysdir}/#{@fqdn}.pem"
@certsfile        = "#{certsdir}/#{@fqdn}.pem"

output             = {}
output['requests'] = {}

def request(method, path, header, data = {})
  host = @fqdn
  port = 8140
  uri  = URI.parse("https://#{host}:#{port}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.key  = OpenSSL::PKey::RSA.new(File.read(@private_keysfile)) if File.exist?(@private_keysfile)
  http.cert = OpenSSL::X509::Certificate.new(File.read(@certsfile)) if File.exist?(@certsfile)
  request = Net::HTTP.const_get("#{method.to_s.capitalize}").new(uri.request_uri, header)
  request.body = data.to_json
  response = http.request(request)
  response
end

def requestFind(target)
  method = 'GET'
  path   = "/production/certificate_status/#{target}"
  header = { 'Accept' => 'application/json' }
  request(method, path, header)
end

def requestRevoke(target)
  method = 'PUT'
  path   = "/production/certificate_status/#{target}"
  header = { 'Content-Type' =>  'text/pson' }
  data   = { 'desired_state' => 'revoked' }
  request(method, path, header, data)
end

def requestClean(target)
  method = 'DELETE'
  path   = "/production/certificate_status/#{target}"
  header = { 'Accept' =>  'pson' }
  request(method, path, header)
end

case restore
when false
  begin
    response_find = requestFind(target)
    output['requests']['find'] = JSON.parse(response_find.body.to_s)
  rescue JSON::ParserError => e  
    output['status'] = 'unchanged'
    exit 0
  end
  output['status']             = 'changed'
  output['message']            = "revoked certificated for #{target}"
  response_revoke              = requestRevoke(target)
  response_clean               = requestClean(target)
  output['requests']['revoke'] = response_revoke.body.to_s
  output['requests']['clean']  = response_clean.body.to_s
when true # restore
	 output['status'] = 'no_restore'
end

puts output.to_json