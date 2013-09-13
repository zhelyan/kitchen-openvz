require "kitchen"
require "ipaddr"


class IPAddr
  def get_mask
    self.instance_eval{ _to_string(@mask_addr)}
  end

  def get_cid
    IPAddr.new(get_mask).to_i.to_s(2).count("1")
  end
end

module Kitchen
  module Driver
    class Openvz < Kitchen::Driver::SSHBase

      no_parallel_for :create

      CONTAINER_ROOT = "/vz/root".freeze
      PK_PATT = '~/.ssh/*.pub'.freeze

      default_config :use_sudo, false
      default_config :port, 22
      default_config :username, "root"
      default_config :password, "root"
      default_config :ssh_key, "/root/.ssh/id_rsa"
      default_config :ssh_public_key, "/root/.ssh/id_rsa.pub"

      default_config :container_path, "/vz/template/cache"

      def create(state)

        raise("! Please specify template") if !config[:template]

        state[:ctid] = config[:ctid] = auto_ctid()
        state[:hostname] = config[:hostname] || auto_ip()

        info("Creating OpenVZ container #{config[:ctid]}")
        run_command("vzctl create #{config[:ctid]} --ostemplate #{config[:template]}")
        run_command("vzctl set #{config[:ctid]} --ipadd #{state[:hostname]} --save")

        #any vz options
        set_openvz_opts()
        # override with explicit usr/pass if given
        set_option('userpasswd', "#{config[:username]}:#{config[:password]}")

        set_memory()
        setup_nat()

        info("Starting OpenVZ container ID:#{config[:ctid]}, hostname:: #{state[:hostname]}")
        run_command("vzctl start #{config[:ctid]}")

        # has to be done after start
        setup_pk_auth()

        # do this until kitchen is fixed to wait properly for sshd
        i = 0
        unless `vzctl exec #{config[:ctid]} ps -ef | grep sshd` =~ /\/sshd/
          puts "waiting for sshd"
          sleep(2)
        end
        sleep(7)
        ############################################################

        # run after boot customization
        before_provision()

        wait_for_sshd(state[:hostname])
      end



      def destroy(state)
        if state[:ctid] && File.directory?("#{CONTAINER_ROOT}/#{state[:ctid]}")
          info("Destroying container #{state[:ctid]}, template: #{state[:template]}")
          run_command("vzctl stop #{state[:ctid]}")
          run_command("vzctl destroy #{state[:ctid]}")
        end
      end


      def set_memory
        if config[:memory_mb]
          basemem = mb_to_pages(config[:memory_mb])
          totalmem = basemem + mb_to_pages(8)
          set_option('vmguarpages', basemem)
          set_option('oomguarpages ', totalmem)
        end
      end



      def setup_pk_auth
        pub_key =  Dir["#{File.expand_path(PK_PATT)}"].first
        unless pub_key
          puts "* No identities found, skipping PK auth"
          return
        end
        container_root = "#{CONTAINER_ROOT}/#{config[:ctid]}"
        run_command("mkdir -p #{container_root}/root/.ssh")
        run_command("chmod 0700 #{container_root}/root/.ssh")
        run_command("cp #{pub_key} #{container_root}/root/.ssh/authorized_keys")
        run_command("chmod 0644 #{container_root}/root/.ssh/authorized_keys")
      end

      def before_provision
        if config[:before_provision]
          run_command("vzctl exec #{config[:ctid]} #{config[:before_provision].split(/\r?\n/).join('; ')}")
        end
      end

      def setup_nat()
        # not my business :-)
        #if config[:nat]
        #  #run_command("iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to 192.168.2.83")
        #end
      end

      def auto_ctid
        r = `vzlist -o ctid -H -a`
        return 1 if r.empty? # stderr not captured, assuming no containers created
        taken_ids = r.split(/\r?\n/).map { |e| e.to_i }
        allocate_ctid(taken_ids)
      end

      def allocate_ctid(not_in)
        orphan = not_in.sort.find { |p| !not_in.include?(p+1) }
        orphan.to_i + 1
      end

      def auto_ip
        ip = IPAddr.new('10.1.1.0/24')
        r = `vzlist -o ip -H -a`
        allocated_ips = r.split(/\r?\n/).sort
        allocate_ip(ip, allocated_ips)
      end

      def allocate_ip(ip, not_in)
        return ip.to_s if not_in.empty?
        start = ip.to_range.to_a.map{|s| s.to_s} - [ip.to_s]  # exclude broadcast
        free =  start - not_in
        raise "* No free ips in range: #{start}" if free.empty?
        "#{free.first}/24"
      end

      def set_openvz_opts
        return if !config[:openvz_opts]
        config[:openvz_opts].each_pair do |k, v|
          set_option(k, v)
        end
      end


      def set_option(k, v)
        run_command("vzctl set #{config[:ctid]} --#{k} #{v} --save")
      end

      def mb_to_pages(megabytes)
        (megabytes.to_f / 4096 * 1024 * 1024).ceil
      end

    end

  end
end

