require 'capistrano-scrip/utils'

# System tasks (users/permissions management)
#
# Main task is +host:setup+ which will prepare servers for deploy - create config files
# and directories required for deploy.
Capistrano::Configuration.instance.load do
  namespace :host do
    # User with root privileges on server. +host:setup+ and all +*:setup_host+ tasks are performed
    # on behalf of this user.
    _cset(:root_user) {"root"}
    # Home path for deployer
    # (used in host:create_user task)
    _cset(:user_home_path) { "/home/www/#{fetch(:deploy_user, user)}" }
    # Path to public key (or public key itself as string)
    _cset(:ssh_public_key) { "~/.ssh/id_rsa.pub" }

    desc "Creates user, enables ssh authorization"
    host_task :create_user do
      script = <<-eos
        set -e;
        if #{sudo} id -u #{deploy_user} >/dev/null 2>&1 ; then
          echo "User '#{deploy_user}' already exists";
        else
          #{sudo} useradd #{deploy_user} -d #{user_home_path};
          #{sudo} mkdir -p #{user_home_path};
          #{sudo} chown #{deploy_user}:#{group} #{user_home_path};
          echo "Created user #{deploy_user} with home #{user_home_path}";
        fi;
      eos
      if exists?(:rvm_ruby_string)
        script << <<-eos
          if #{sudo} getent group rvm >/dev/null 2>&1; then
            #{sudo} usermod -a -G rvm #{deploy_user};
          fi;
        eos
      end
      run script
    end

    desc <<-EOF
    Copy your public key to server. Path to key can be configured via {ssh_public_key}

    You can also provide public key string itself as ssh_public_key:

        set(:ssh_public_key) { "ssh-rsa AAAAB3N....2zQ== host@user" }

    Also you can specify ssh_public_key via CLI:

        !!!bash
        cap host:ssh_copy_id -s ssh_public_key="AAAAB3N....2zQ== host@user"
    EOF
    host_task :ssh_copy_id do
      key_path = File.expand_path(ssh_public_key)
      if File.exist?(key_path)
        key_string = IO.readlines(key_path)[0]
      else
        key_string = ssh_public_key
      end
      run <<-eos
        set -e;
        #{sudo :as => deploy_user} mkdir -p ~#{deploy_user}/.ssh;
        if #{sudo} grep -q -s -F '#{key_string}' ~#{deploy_user}/.ssh/authorized_keys ; then
          echo "Key already in authorized keys.";
        else
          #{sudo :as => deploy_user} touch ~#{deploy_user}/.ssh/authorized_keys;
          echo '#{key_string}' | #{sudo :as => deploy_user} tee -a ~#{deploy_user}/.ssh/authorized_keys;
          echo "Added #{key_path} to authorized_keys of #{deploy_user}";
        fi;
      eos
    end

    desc <<-EOF
    Creates deploy user on target system, adds him to sudoers, etc.

    Also performs deploy:setup and *:setup_host for all loaded recipes, so it will
    create configs for monit / nginx / whatever you loaded via require "capistrano-script/.."

    It is safe to run this task on servers that have already been set up;
    it will not create extra users / destroy config files or data.
    EOF
    task :setup do
      # It's not "host" task because inner tasks are host_tasks (not all of them)
      create_user
      ssh_copy_id

      deploy.setup
    end
  end
end
