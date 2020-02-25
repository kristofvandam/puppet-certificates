#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'yaml'
require 'puppet'
require 'facter'
require 'fileutils'

Puppet.initialize_settings

params             = JSON.parse(STDIN.read)
restore            = params['restore'] || false

ssldir             = Puppet.settings.value(:ssldir)
fqdn               = Facter.value(:fqdn)
cert               = "#{ssldir}/certs/#{fqdn}"
certbck            = "#{cert}.bck"

case restore
when false
  cert_original = File.read(cert) if File.file?(cert)
	FileUtils.mv(cert, certbck) if File.file?(cert)
	puts "creating our certificate file"
	#generate cert
when true # restore
	if File.file?(certbck)
	  puts "restoring certificate"
	  File.delete(cert) if File.exist?(cert)
	  FileUtils.mv(certbck, cert)
	else
		puts "no backup to restore"
	end
end