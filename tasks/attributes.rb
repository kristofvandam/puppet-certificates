#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'yaml'
require 'puppet'
require 'facter'
require 'fileutils'

Puppet.initialize_settings

ssldir             = Puppet.settings.value(:ssldir)

csrfile            = "#{ssldir}/csr_attributes.yaml"
csrfilebck         = "#{csrfile}.bck"

params             = JSON.parse(STDIN.read)
restore            = params['restore'] || false
custom_attributes  = params['custom_attributes']  || {}
extension_requests = params['extension_requests'] || {}

def resolve_values(attributes)
	attributes.map { |key, value|
	  value = Facter.value(value.gsub("fact:", "").to_sym) if value =~ /^fact:/
	  [key, value]
	}.to_h
end

csr_attributes = {
	"custom_attributes"  => resolve_values(custom_attributes),
	"extension_requests" => resolve_values(extension_requests)
}.to_yaml

case restore
when false
  csr_original = File.read(csrfile) if File.file?(csrfile)
  if csr_original != csr_attributes
  	FileUtils.mv(csrfile, csrfilebck) if File.file?(csrfile)
  	puts "creating our csr_attributes file"
  	File.write(csrfile, csr_attributes)
  else
  	puts "csr_attributes already matches the desired state"
  end
when true # restore
	if File.file?(csrfilebck)
	  puts "restoring csr_attributes"
	  File.delete(csrfile) if File.exist?(csrfile)
	  FileUtils.mv(csrfilebck, csrfile)
	else
		puts "no backup to restore"
	end
end