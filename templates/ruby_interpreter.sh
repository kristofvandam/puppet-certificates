#!/bin/env bash
if [[ -x /opt/puppetlabs/puppet/bin/ruby ]]; then
  exec /opt/puppetlabs/puppet/bin/ruby $@
else
  exec $(which ruby) $@
fi