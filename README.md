# Kitchen::Openvz

Use OpenVZ containers with test-kitchen.

## Installation

Add this line to your application's Gemfile:

    gem 'kitchen-openvz'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kitchen-openvz

## Requirements

- OpenVZ installed on your machine or VM, please refer to:: http://openvz.org/Quick_installation
- one or more containers in /vz/templates/cache, have a look here:: http://openvz.org/Download/template/precreated; Containers will be downloaded automatically if they don't exist.
- RHEL / CENTOS.


## Options

### use_sudo

Whether to use sudo or not.

### port

SSH port to bind to.

### container_id

The container `CTID`. The driver will auto increment this it finds that it is already taken.
Defaults to:: `101`

### hostname

Container IP address. The driver will autoincrement it if it is already taken. Defaults to:: `10.1.1.1`

### shared_folders

One or more host folders mounts i.e. `[['/host/folder1', '/guest/folder1'], ['/host/folder2', '/guest/folder2']]`

### openvz_home

Path to openvz home. Defaults to: `/vz`.


### lock_file

Where to create the lock file. This is needed as sometimes the `create` action needs to query other running containers to i.e. auto increment IPs/CTIDs.
Defaults to:: `/var/run/kitchen-openvz.lock`.

### ssh_public_key

Path to the SSH public key to use. Defaults to:: `/root/.ssh/id_rsa.pub`

### customize

The customize section is provided for convenience since the `vzctl set` commands are slightly cryptic. It contains 3 settings `memory, swap, vcpu` allowing users to set RAM, swap and CPU count respectively.
The same result can be achieved by passing the equivalent settings in the `openvz_opts` section /see below/. Moreover, if duplicated, options specified in `openvz_opts` take precedence.

#### memory

Container RAM limit. Defaults to:: 256MB. Use only digits when specifying in the kitchen file.

#### swap

Container swap memory. Defaults to:: 512MB. Same remark as in `memory`.

#### vcpu

Number of CPUs. Defaults to:: `1`

### openvz_opts

Extra options to pass to `vzctl set`. Note that anything under here will be passed to `vzctl set` as is.


## Example:

Look at the included `example_.kitchen.yml`.

## Notes

NAT : refer to the OpenVZ guide to setup NAT and provide Internet access to the container(s) :: https://openvz.org/Using_NAT_for_container_with_private_IPs

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
