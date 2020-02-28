#!/tmp/ruby

require 'json'
require 'puppet'

params             = JSON.parse(STDIN.read)
restore            = params['restore'] || false

output             = {}

Puppet.initialize_settings
Puppet::SSL::Oids.register_puppet_oids
Puppet.settings.use :main, :agent, :ssl

def certificateRequestPP5()
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

def certificateRequestPP6()
	machine = Puppet::SSL::StateMachine.new(waitforcert: 0)
	begin
		machine.ensure_client_certificate
	rescue Exception => e
		output['status'] = 'changed'
		output['err'] = "#{e}"
	end	
end

if not restore
	major_version = Puppet.version
	case major_version
	  when /^5/
	  	certificateRequestPP5
	  when /^6/
	  	certificateRequestPP6
	end
else
	output['status'] = 'no_restore'
end

puts output.to_json