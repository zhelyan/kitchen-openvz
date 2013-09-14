# Kitchen::Openvz

Use OpenVZ containers with test-kitchen

OpenVZ can run on both hardware node or a VM i.e. you can have virtualized containers for your tests runing in a Vagrant VM

## Installation

Add this line to your application's Gemfile:

    gem 'kitchen-openvz'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kitchen-openvz

## Requirements

- OpenVZ installed on your machine or VM, please refer to:: http://openvz.org/Quick_installation
- one or more containers in /vz/templates/cache, have a look here:: http://openvz.org/Download/template/precreated
- RHEL / CENTOS 6; It is possible to install OpenVZ on 5 as well but not as easy as on 6


## Usage

Look at the included .kitchen.yml for an example

*Notes*

- Container IDs
 - OpenVZ allocates an unique `ctid` to each container. The driver will do this for you in increments of 1. Should you need to explicitly set the ctid for you container, use the `ctid` option

- Network
 - NAT : refer to the OpenVZ guide to setup NAT and provide Internet access to the container/s/ :: https://openvz.org/Using_NAT_for_container_with_private_IPs
 - the `network` setting takes single ip or CIDR notation, i.e:: 10.1.1.7 or  10.1.1.0/24; there is no default, the driver will allocate one automatically for you looking for free ips in 10.1.1.0/24 excluding the broadcast address.
||
- Authentication
 - by default `/root/.ssh/id_rsa.pub` is used, override with the `ssh_public_key` option
 - if no public key is found, the driver will fall back to password authentication; defaults to root:root
||
- Options
 - specify `vzctl set` options under the `openvz_opts` option
 - `before_converge` takes multiline text, each line will be executed as is on the host before convergence
 - use `memory_mb` to allocate memory /in MB/ to the container. Note that the value specified here will override any memory options you might have set in `openvz_opts`.



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
