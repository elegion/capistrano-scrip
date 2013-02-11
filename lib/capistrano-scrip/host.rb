require 'capistrano-scrip/utils'

Capistrano::Configuration.instance.load do
  namespace :rvm do
    task :install_rvm do
      run "#{sudo} #{rvm_install_shell} -s #{rvm_install_type} \
< <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)", :shell => "#{rvm_install_shell}"
    end

    task :install_ruby do
      ruby, gemset = rvm_ruby_string.to_s.strip.split /@/
      if %w( release_path default ).include? "#{ruby}"
        raise "ruby can not be installed when using :rvm_ruby_string => :#{ruby}"
      else
        run "#{sudo} #{File.join(rvm_bin_path, "rvm")} #{rvm_install_ruby} #{ruby} -j #{rvm_install_ruby_threads}", :shell => "#{rvm_install_shell}"
        if gemset
          run "#{sudo} #{File.join(rvm_bin_path, "rvm")} #{ruby} do rvm gemset create #{gemset}", :shell => "#{rvm_install_shell}"
        end
      end
    end
  end
  task :create_gemset do
    ruby, gemset = rvm_ruby_string.to_s.strip.split /@/
    if %w( release_path default ).include? "#{ruby}"
      raise "gemset can not be created when using :rvm_ruby_string => :#{ruby}"
    else
      if gemset
        run "#{File.join(rvm_bin_path, "rvm")} #{ruby} do rvm gemset create #{gemset}", :shell => "#{rvm_install_shell}"
      end
    end
  end

  namespace :host do
    _cset(:root_user) {"root"}
    _cset(:user_home_path) { "/home/www/#{deploy_user || user}" }
    _cset(:ssh_public_key) { "~/.ssh/id_rsa.pub" }

    desc "Creates user, enables ssh authorization"
    task :create_user do
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
        script << "#{sudo} usermod -a -G rvm #{deploy_user};"
      end
      run script
    end

    desc "Copy your public key to server"
    task :ssh_copy_id do
      key_path = File.expand_path(ssh_public_key)
      if File.exist?(key_path)
        key_string = IO.readlines(key_path)[0]
      else
        key_string = ssh_public_key
      end
      run <<-eos
        set -e;
        #{sudo :as => deploy_user} mkdir -p #{user_home_path}/.ssh;
        if #{sudo} grep -q -s -F '#{key_string}' #{user_home_path}/.ssh/authorized_keys ; then
          echo "Key already in authorized keys.";
        else
          #{sudo :as => deploy_user} touch #{user_home_path}/.ssh/authorized_keys;
          echo '#{key_string}' | #{sudo :as => deploy_user} tee -a #{user_home_path}/.ssh/authorized_keys;
          echo "Added #{key_path} to authorized_keys of #{deploy_user}";
        fi;
      eos
    end

    desc "Creates deploy user on target system, adds him to sudoers, etc"
    task :setup do
      set :deploy_user, user
      set :user, root_user
      #rvm.install_rvm
      #rvm.install_ruby
      create_user
      ssh_copy_id

      with_user deploy_user do
        deploy.setup
      end
    end
  end
end
