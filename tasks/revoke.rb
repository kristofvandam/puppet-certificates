#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'puppet'
require 'facter'
require 'fileutils'

Puppet.initialize_settings

params             = JSON.parse(STDIN.read)
restore            = params['restore'] || false
target             = params['target']

ssldir             = Puppet.settings.value(:ssldir)
cadir			         = "#{ssldir}/ca"
signeddir          = "#{cadir}/signed"
revokeddir		     = "#{cadir}/revoked"

signedcert         = "#{signeddir}/#{target}.pem"
revokedcert        = "#{revokeddir}/#{target}.pem"

# Ensure the revoked directory is present
unless File.directory?(revokeddir)
  FileUtils.mkdir_p(revokeddir)
end

case restore
when false
	if File.file?(signedcert)
	  puts "revoking certificate: #{signedcert}"
	  FileUtils.mv(signedcert, revokedcert)
	 else
	 	 puts "already revoked certificate: #{signedcert}"
	end
when true # restore
	if File.file?(revokedcert)
	  puts "restoring certificate: #{signedcert}"
	  FileUtils.mv(revokedcert, signedcert)
	else
		puts "already restored certificate: #{signedcert}"
	end
end