require 'kitchen'
require 'ipaddr'
require 'ipaddress'
require 'net/http'

module Kitchen
  module Driver
    class Openvz < Kitchen::Driver::SSHBase
      DEFAULT_CONTAINER_ID = 101
      DEFAULT_CONTAINER_IP_ADDRESS = '10.1.1.1'

      no_parallel_for :create

      default_config :use_sudo, true
      default_config :customize, { :memory => 256, :swap => 512, :vcpu => 1 }
      default_config :port, 22
      default_config :username, 'root'
      default_config :ssh_key, '/root/.ssh/id_rsa'
      default_config :ssh_public_key, '/root/.ssh/id_rsa.pub'
      default_config :openvz_home, '/vz'
      default_config :lock_file, '/var/run/kitchen-openvz.lock'

      def create(state)
        state[:container_id] = config[:container_id] || next_container_id
        state[:hostname] = config[:hostname] || next_ip_address
        create_container(state)
        start_container(state)
        wait_for_sshd(state[:hostname])
        # If ssh is responding then the template has been exploded so we can deploy the ssh key
        deploy_ssh_key(state)
      end

      def destroy(state)
        if state[:container_id] && container_exists(state[:container_id])
          debug("Destroying container #{state[:container_id]}")
          run_command("vzctl stop #{state[:container_id]}")
          run_command("vzctl destroy #{state[:container_id]}")
        end
      end

      private

      def next_container_id
        info('Generating next container id in sequence')
        with_global_mutex do 
          output = run_command('vzlist -o ctid -H -a')
          taken_ids = output.to_s.lines.map { |line| line.to_i }
          if taken_ids.any?
            new_id = taken_ids.max + 1
            debug("Generated new container id #{new_id}")
            new_id
          else
            debug("No existing containers found, using default id #{DEFAULT_CONTAINER_ID}")
            DEFAULT_CONTAINER_ID
          end
        end
      end

      def next_ip_address
        info('Generating next IP address in sequence')
        with_global_mutex do
          output = run_command('vzlist -o ip -H -a')
          taken_ips = parse_ip_addresses(output)
          if taken_ips.any?
            new_ip = taken_ips.max.succ.to_s
            debug("Generated new IP address #{new_ip}")
            new_ip
          else
            debug("No existing IP addresses found, using default #{DEFAULT_CONTAINER_IP_ADDRESS}")
            DEFAULT_CONTAINER_IP_ADDRESS
          end
        end
      end

      def parse_ip_addresses(content)
        valid_ips = content.to_s.lines.select { |line| IPAddress.valid?(line) }
        debug("Parsing IP addresses: #{valid_ips}")
        valid_ips.map { |ip| IPAddr.new(ip.chomp) }
      end

      def create_container(state)
        if !File.exists?(File.join(config[:openvz_home], "/template/cache/#{instance.platform.name}.tar.gz"))
          info("OpenVZ template #{instance.platform.name} does not currently exist, will attempt to download...")
          download_template(instance.platform.name)
        end

        info("Creating OpenVZ container #{state[:container_id]} from template #{instance.platform.name}")
        run_command("vzctl create #{state[:container_id]} --ostemplate #{instance.platform.name}")

        configure_container(state)
      end

      def configure_container(state)
        container_id = state[:container_id]
        info("Setting IP address of container #{container_id} to #{state[:hostname]}")
        set_container_option(container_id, 'ipadd', state[:hostname])

        hostname = "server#{container_id}.example.com"
        info("Setting hostname of container #{container_id} to #{hostname}")
        set_container_option(container_id, 'hostname', hostname)

        info("Setting RAM limit on container #{container_id} to #{config[:customize][:memory]}")
        set_container_option(container_id, 'ram', "#{config[:customize][:memory]}M")

        info("Setting swap limit on container #{container_id} to #{config[:customize][:swap]}")
        set_container_option(container_id, 'swap', "#{config[:customize][:swap]}M")

        info("Setting CPU count on container #{container_id} to #{config[:customize][:vcpu]}")
        set_container_option(container_id, 'cpus', config[:customize][:vcpu])

        info("Setting custom properties #{config[:openvz_opts]} on container #{container_id}")
        config[:openvz_opts].each_pair do |option, value|
          set_container_option(container_id, option, value)
        end if config[:openvz_opts]
      end

      def set_container_option(container_id, option, value)
        run_command("vzctl set #{container_id} --#{option} #{value} --save")
      end

      def start_container(state)
        info("Starting OpenVZ container #{state[:container_id]}")
        run_command("vzctl start #{state[:container_id]}")
      end

      def deploy_ssh_key(state)
        ssh_dir = File.join(config[:openvz_home], 'root', state[:container_id].to_s, 'root', '.ssh')
        run_command("mkdir -p #{ssh_dir}")
        run_command("chmod 0700 #{ssh_dir}")

        authorized_keys_path = File.join(ssh_dir, 'authorized_keys')
        run_command("cp #{config[:ssh_public_key]} #{authorized_keys_path}")
        run_command("chmod 0644 #{authorized_keys_path}")
      end

      def container_exists(id)
        output = run_command('vzlist -o ctid -H -a')
        ids = output.to_s.lines.map { |line| line.to_i }
        ids.include?(id)
      end

      OPENVZ_TEMPLATE_URL = 'http://download.openvz.org/template/precreated/'.freeze

      def download_template(name)
        template_directory = File.join(config[:openvz_home], 'template', 'cache')
        download_url = "#{OPENVZ_TEMPLATE_URL}/#{name}.tar.gz"
        debug("Downloading OpenVZ template #{name} from #{download_url}")
        run_command("wget #{download_url} -P #{template_directory}")
      end

      def with_global_mutex(&block)
        lock_file = File.open(config[:lock_file], 'w')
        begin
          debug('Taking mutex')
          lock_file.flock(File::LOCK_EX)
          block.call
        ensure
          lock_file.flock(File::LOCK_UN)
          debug('Released mutex')
        end
      end
    end
  end
end
