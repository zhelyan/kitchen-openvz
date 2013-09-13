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
- RHEL / CENTOS 6; It is possible to install OpenVZ on 5 as well but it is not as straightforward as on 6


## Usage

Look at the included .kitchen.yml for an example

*Notes*

- Network
 - NAT : refer to the OpenVZ guide to setup NAT and provide Internet access to the container/s/ :: https://openvz.org/Using_NAT_for_container_with_private_IPs
 - the 'network' setting takes single or masked ip, i.e:: 10.1.1.7 or  10.1.1.0/24; the default is 10.1.1.0/24
 - in the first case /single ip/ make sure that the ip isn't allocated to another container.
 - if you provide a range, the driver will automatically assign a free IP from the range pool to the container (given that there are free IPs in the pool)
||
- Authentication
 - the driver uses current user's public ssh key to setup PK auth
 - it will fal back to password authentication if no public keys exist in ~/.ssh; The default user/pass is root:root, you can override by setting 'username' and 'password' in .kitchen.yaml



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
