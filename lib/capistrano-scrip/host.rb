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
    set :root_user, "root" unless exists?(:root_user)
    set(:user_home_path) { "/home/www/#{deploy_user || user}" } unless exists?(:user_home_path)
    set(:ssh_public_key) { "~/.ssh/id_rsa.pub" } unless exists?(:ssh_public_key)

    desc "Creates user, enables ssh authorization"
    task :create_user do
      run "#{sudo} grep -q \"^#{deploy_user}:\" /etc/passwd || " \
        "#{sudo} useradd #{deploy_user} -d #{user_home_path} && " \
        "#{sudo} mkdir -p #{user_home_path} && "\
        "#{sudo} chown #{deploy_user}:#{group} #{user_home_path}"
      if exists?(:rvm_ruby_string)
        run "#{sudo} usermod -a -G rvm #{deploy_user}"
      end
    end

    desc "Copy your public key to server"
    task :ssh_copy_id do
      key_path = File.expand_path(ssh_public_key)
      if File.exist?(key_path)
        key_string = IO.readlines(key_path)[0]
      else
        key_string = ssh_public_key
      end
      run "#{sudo :as => deploy_user} touch #{user_home_path}/.ssh/authorized_keys && " \
        "#{sudo} grep -q -F '#{key_string}' #{user_home_path}/.ssh/authorized_keys || " \
        "#{sudo :as => deploy_user} mkdir -p #{user_home_path}/.ssh && " \
        "echo '#{key_string}' | #{sudo :as => deploy_user} tee -a #{user_home_path}/.ssh/authorized_keys"
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
