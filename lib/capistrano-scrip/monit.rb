require 'capistrano-scrip/utils'

# monit is a free, open source process supervision tool for Unix and Linux.
Capistrano::Configuration.instance.load do
  # Path to monit configuration template
  _cset(:monit_config_template) { "monit/monit_#{app_server}.conf.erb" }
  # The remote location of monit's config file
  _cset(:monit_config_path) { "/etc/monit/conf.d/#{application}-#{app_server}" }
  # Path to monit binary on server
  _cset(:monit_command) { "monit" }

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
    Parses the configuration template file :{monit_config_template} through ERB to fetch our variables \
    and uploads the result to :{monit_config_path}
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(monit_config_template, monit_config_path)
    end

    desc "Parses config file and outputs it to STDOUT (internal task) "
    task :parse_config, :roles => :app , :except => { :no_release => true } do
      puts parse_template(monit_config_template)
    end

    desc <<-EOF
    Creates empty monit configuration file for this application, grants user permissions to modify it
    EOF
    host_task :setup_host do
      run "#{sudo} touch #{monit_config_path} && " \
          "#{sudo} chown #{deploy_user}:#{group} #{monit_config_path}"

      with_user deploy_user do
        monit.setup
      end
    end
  end

  after 'host:setup' do
    monit.setup_host #if Capistrano::CLI.ui.agree("Create monit-related files? [Yn]")
  end
end
