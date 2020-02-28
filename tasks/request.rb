#!/opt/puppetlabs/puppet/bin/ruby
require 'json'
require 'puppet'

params             = JSON.parse(STDIN.read)
restore            = params['restore'] || false

output             = {}

Puppet.initialize_settings
Puppet::SSL::Oids.register_puppet_oids
Puppet.settings.use :main, :agent, :ssl

def CertificateRequestPP5
	require 'puppet/application/agent'

	Puppet::SSL::Host.ca_location = :remote
	machine = Puppet::Application::Agent.new
	begin
		machine.setup
		host = Puppet::SSL::Host.new
		host.wait_for_cert(0)
	rescue Exception => e
		output['status'] = 'changed'
		output['err'] = "#{e}"
	end	
end

def CertificateRequestPP6
	machine = Puppet::SSL::StateMachine.new(waitforcert: 0)
	begin
		machine.ensure_client_certificate
	rescue Exception => e
		output['status'] = 'changed'
		output['err'] = "#{e}"
	end	
end

if not restore
	major_version = Puppet.version.split('.', 1)
	CertificateRequest.const_get("PP#{major_version}")
else
	output['status'] = 'no_restore'
end

puts output.to_json