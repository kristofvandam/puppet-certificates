#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'yaml'
require 'puppet'
require 'facter'
require 'fileutils'

Puppet.initialize_settings

ssldir             = Puppet.settings.value(:ssldir)
csrfile            = "#{ssldir}/csr_attributes.yaml"

ssldirbck          = "#{ssldir}.bck"
csrfilebck         = "#{csrfile}.bck"

params             = JSON.parse(STDIN.read)
restore            = params['restore'] || false
custom_attributes  = params['custom_attributes']  || {}
extension_requests = params['extension_requests'] || {}

output = {}

def resolve_values(attributes)
	attributes.map { |key, value|
	  value = Facter.value(value.gsub("fact:", "").to_sym) if value =~ /^fact:/
	  [key, value]
	}.to_h
end

csr_attributes_hash = {
	"custom_attributes"  => resolve_values(custom_attributes),
	"extension_requests" => resolve_values(extension_requests)
}
csr_attributes_json      = csr_attributes_hash.to_json
csr_attributes_yaml      = csr_attributes_hash.to_yaml

case restore
when false
  csr_original = YAML.load_file(csrfile).to_json if File.file?(csrfile)
  if csr_original != csr_attributes_json
    FileUtils.remove_dir(ssldirbck) if File.directory?(ssldirbck)
    FileUtils.mv(ssldir, ssldirbck) if File.directory?(ssldir)
    FileUtils.mkdir_p(ssldir) if not File.directory?(ssldir)
  	File.write(csrfile, csr_attributes_yaml)
    output['status'] = 'changed'
  else
    output['status'] = 'unchanged'
  end
when true # restore
	if File.directory?(ssldirbck)
	  FileUtils.remove_dir(ssldir) if File.directory?(ssldir)
	  FileUtils.mv(ssldirbck, ssldir)
    output['status'] = 'restored'
	else
    output['status'] = 'no_restore'
	end
end

output['csr_attributes'] = csr_attributes_hash
puts output.to_json