require 'capistrano-scrip/utils'

Capistrano::Configuration.instance.load do
  # Our monit template to be parsed by erb
  # You may need to generate this file the first time with the generator
  # included in the gem
  set(:monit_local_config) { File.join(templates_path, "monit.erb") } unless exists?(:monit_local_config)

  # The remote location of monit's config file. Used by god to fire it up
  set(:monit_remote_config) { "/etc/monit/conf.d/unicorn-#{application}" } unless exists?(:monit_remote_config)

  set :monit_command, "monit" unless exists?(:monit_command)
  # Monit
  #------------------------------------------------------------------------------
  namespace :monit do
    desc "Reloads monit"
    task :reload, :roles => :app do
      run "#{sudo} #{monit_command} reload"
    end

    namespace :status do
      desc "Status summary"
      task :default do
        run "#{sudo} #{monit_command} summary"
      end

      desc "Full status"
      task :full do
        sudo "#{monit_command} status"
      end
    end

    desc <<-EOF
    Parses the configuration file through ERB to fetch our variables and uploads the \
    result to /etc/monit/conf.d/unicorn-\#{application} (can be configured via \
    :monit_remote_config).
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(monit_local_config, monit_remote_config)
    end

    desc <<-EOF
    Creates empty monit configuration file for this application, allows user to
    modify it.
    EOF
    task :setup_host do
      unless exists?(:deploy_user)
        set :deploy_user, user
        set :user, root_user
      end

      run "#{sudo} touch #{monit_remote_config} && " \
          "#{sudo} chown #{deploy_user}:#{group} #{monit_remote_config}"

      with_user deploy_user do
        monit.setup
      end
    end
  end

  after 'host:setup' do
    monit.setup_host #if Capistrano::CLI.ui.agree("Create monit-related files? [Yn]")
  end
  after 'deploy:setup' do
    monit.setup if !exists?(:deploy_user) && Capistrano::CLI.ui.agree("Create monit configuration file? [Yn]")
  end
end
