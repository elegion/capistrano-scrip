require 'capistrano-scrip/utils'

# Use unicorn as application server (inspired by https://github.com/webficient/capistrano-recipes)
#
# Unicorn is an HTTP server for Rack applications designed to only serve fast clients on low-latency, high-bandwidth
# connections and take advantage of features in Unix/Unix-like kernels.
Capistrano::Configuration.instance.load do
  # App server type, you normally shouldn't change this
  _cset(:app_server) { "unicorn" }

  # Number of workers (Rule of thumb is 2 per CPU)
  # Just be aware that every worker needs to cache all classes and thus eat some
  # of your RAM.
  _cset(:unicorn_workers) { 8 }

  # Workers timeout in the amount of seconds below, when the master kills it and
  # forks another one.
  _cset(:unicorn_workers_timeout) { 30 }

  # Workers are started with this user/group
  # By default we get the user/group set in capistrano.
  _cset(:unicorn_user) { user }
  _cset(:unicorn_group) { group }

  # The wrapped bin to start unicorn
  # This is necessary if you're using rvm
  _cset(:unicorn_bin) { 'bundle exec unicorn' }
  _cset(:unicorn_socket) { "#{shared_path}/socket/unicorn.sock" }

  # Defines where the unicorn pid will live.
  _cset(:unicorn_pid) { "#{shared_path}/pids/unicorn.pid" }

  # Our unicorn template to be parsed by erb
  # You may need to generate this file the first time with the generator
  # included in the gem
  _cset(:unicorn_config_template) { "unicorn.rb.erb" }

  # The remote location of unicorn's config file. Used by god to fire it up
  _cset(:unicorn_config_path) { "#{shared_path}/config/unicorn.rb" }

  # Path to template for shell script to start/stop unicorn
  _cset(:unicorn_script_template) { "unicorn.sh.erb" }

  # The remote location for unicort start/stop script
  _cset(:unicorn_script_path) { "/etc/init.d/unicorn-#{application}.sh" }

  def unicorn_start_cmd
    "#{unicorn_script_path} start"
  end

  def unicorn_stop_cmd
    "#{unicorn_script_path} stop"
  end

  def unicorn_restart_cmd
    "#{unicorn_script_path} upgrade"
  end

  # Unicorn
  #------------------------------------------------------------------------------
  namespace :unicorn do
    desc "Starts unicorn directly"
    task :start, :roles => :app do
      run unicorn_start_cmd
    end

    desc "Stops unicorn directly"
    task :stop, :roles => :app do
      run unicorn_stop_cmd
    end

    desc "Restarts unicorn directly"
    task :restart, :roles => :app do
      run unicorn_restart_cmd
    end

    desc "Parses config file and outputs it to STDOUT (internal task)"
    task :parse_config, :roles => :app , :except => { :no_release => true } do
      puts parse_template(unicorn_config_template)
    end

    desc "Parses script file and outputs it to STDOUT (internal task)"
    task :parse_script, :roles => :app , :except => { :no_release => true } do
      puts parse_template(unicorn_script_template)
    end

    desc <<-EOF
    Parses the configuration file through ERB to fetch our variables and \
    uploads the result to \#{shared_path}/config/unicorn.rb (can be configured via \
    :unicorn_config_path), to be loaded by whoever is booting up the unicorn.
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      # TODO: refactor this to a more generic setup task once we have more socket tasks.
      create_remote_dir(File.dirname(unicorn_socket)) if unicorn_socket

      generate_config(unicorn_config_template,unicorn_config_path)
      generate_config(unicorn_script_template,unicorn_script_path)
    end

    desc <<-EOF
    Creates unicorn run script, grants user permissions to modify and run it.
    Creates unicorn config file and grants user permissions to modify it.
    EOF
    host_task :setup_host do
      run "#{sudo} touch #{unicorn_script_path} && " \
          "#{sudo} chown #{deploy_user}:#{group} #{unicorn_script_path} && " \
          "#{sudo} chmod u+x #{unicorn_script_path}"

      with_user deploy_user do
        unicorn.setup
      end
    end
  end

  namespace :deploy do
    task :restart do
      unicorn.restart
    end
    task :start do
      unicorn.start
    end
    task :stop do
      unicorn.stop
    end
  end

  after 'host:setup' do
    unicorn.setup_host #if Capistrano::CLI.ui.agree("Create unicorn run script? [Yn]")
  end
  after 'deploy:setup' do
    unicorn.setup if !exists?(:deploy_user) && Capistrano::CLI.ui.agree("Create unicorn configuration file? [Yn]")
  end
end
