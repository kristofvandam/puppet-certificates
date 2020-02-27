#!/opt/puppetlabs/puppet/bin/ruby
require 'json'
require 'puppet'

params             = JSON.parse(STDIN.read)
restore            = params['restore'] || false

output             = {}

if not restore
	Puppet.initialize_settings
	Puppet::SSL::Oids.register_puppet_oids
	Puppet.settings.use :main, :agent, :ssl
	machine = Puppet::SSL::StateMachine.new(waitforcert: 0)
	begin
		machine.ensure_client_certificate
	rescue Exception => e
		output['status'] = 'changed'
		output['err'] = "#{e}"
	end
else
	output['status'] = 'no_restore'
end

puts output.to_json