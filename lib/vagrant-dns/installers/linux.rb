module VagrantDNS
  module Installers
    class Linux
      EXEC_STYLES = %i{sudo}

      attr_accessor :tmp_path, :install_path, :exec_style

      def initialize(tmp_path, options = {})
        self.tmp_path     = tmp_path
        self.install_path = options.fetch(:install_path, "/etc/NetworkManager/dnsmasq.d")
        self.exec_style   = options.fetch(:exec_style, :sudo)
      end

      def install!
        require 'fileutils'

        commands = [
          ['mkdir', '-p', install_path]
        ]

        commands += registered_resolvers.map do |resolver|
          ['ln', '-sf', resolver.shellescape, install_path.shellescape]
        end

        exec(*commands)
      end

      def uninstall!
        require 'fileutils'

        commands = registered_resolvers.map do |r|
          installed_resolver = File.join(install_path, File.basename(r))
          ['rm', '-rf', installed_resolver]
        end

        exec(*commands)
      end

      def purge!
        require 'fileutils'
        uninstall!
        FileUtils.rm_r(tmp_path)
      end

      def registered_resolvers
        Dir[File.join(tmp_path, "resolver", "*")]
      end

      def exec(*commands)
        return if !commands || commands.empty?

        case exec_style
        when :sudo
          commands.each do |c|
            system 'sudo', *c
          end
        else
          raise ArgumentError, "Unsupported execution style: #{exec_style}. Use one of #{EXEC_STYLES.map(&:inspect).join(' ')}"
        end
      end
    end
  end
end
