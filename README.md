# certificates

## Description

This plan can be used to regenerate client certificates to add trusted facts

## Setup

### What certificates affects

This plan will connect to target aswel as the master to revoke and sign certificates


## Usage

add trusted facts for every target with master 'mm01-puppet', the extension_request json can have 'magic' values to let the target know we need to
'resolve' the fact. (fact:fqdn) for example.
```
bolt plan run certificates::regenerate --targets targets master='mm01-puppet' extension_requests='{"1.3.6.1.4.1.34380.1.2.1": "fact:fqdn", "1.3.6.1.4.1.34380.1.2.2": "L12345"}'
```