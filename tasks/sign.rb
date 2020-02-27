#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'puppet'
require 'facter'
require 'fileutils'
require 'net/http'

Puppet.initialize_settings

params             = JSON.parse(STDIN.read)
restore            = params['restore'] || false
target             = params['target']

@fqdn               = Facter.value(:fqdn)

ssldir             = Puppet.settings.value(:ssldir)
private_keysdir    = "#{ssldir}/private_keys"
certsdir           = "#{ssldir}/certs"

@private_keysfile   = "#{private_keysdir}/#{@fqdn}.pem"
@certsfile          = "#{certsdir}/#{@fqdn}.pem"

output              = {}
output['requests']  = {}

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
  http.request(request)
end

def requestSave(target)
  method = 'PUT'
  path   = "/production/certificate_status/#{target}"
  header = { 'Content-Type' =>  'text/pson' }
  data   = { 'desired_state' => 'signed' }
  request(method, path, header, data)
end

case restore
when false
  response_save = requestSave(target)
  output['status']           = 'changed'
  output['requests']['save'] = response_save.body.to_s
when true # restore
end

puts output.to_json