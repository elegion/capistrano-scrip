require 'capistrano-scrip/utils'

Capistrano::Configuration.instance.load do
  # Number of workers (Rule of thumb is 2 per CPU)
  # Just be aware that every worker needs to cache all classes and thus eat some
  # of your RAM.
  set :unicorn_workers, 8 unless exists?(:unicorn_workers)

  # Workers timeout in the amount of seconds below, when the master kills it and
  # forks another one.
  set :unicorn_workers_timeout, 30 unless exists?(:unicorn_workers_timeout)

  # Workers are started with this user/group
  # By default we get the user/group set in capistrano.
  set(:unicorn_user) { user }   unless exists?(:unicorn_user)
  set(:unicorn_group) { group } unless exists?(:unicorn_group)

  # The wrapped bin to start unicorn
  # This is necessary if you're using rvm
  set :unicorn_bin, 'bundle exec unicorn' unless exists?(:unicorn_bin)
  set(:unicorn_socket) { File.join(sockets_path,'unicorn.sock') } unless exists?(:unicorn_socket)

  # Defines where the unicorn pid will live.
  set(:unicorn_pid) { File.join(pids_path, "unicorn.pid") } unless exists?(:unicorn_pid)

  # Our unicorn template to be parsed by erb
  # You may need to generate this file the first time with the generator
  # included in the gem
  set(:unicorn_local_config) { File.join(templates_path, "unicorn.rb.erb") } unless exists?(:unicorn_local_config)

  # The remote location of unicorn's config file. Used by god to fire it up
  set(:unicorn_remote_config) { "#{shared_path}/config/unicorn.rb" } unless exists?(:unicorn_remote_config)

  # Path to template for shell script to start/stop unicorn
  set(:unicorn_local_script) { File.join(templates_path, "unicorn.sh.erb") } unless exists?(:unicorn_local_script)

  # The remote location for unicort start/stop script
  set(:unicorn_remote_script) { "/etc/init.d/unicorn-#{application}.sh" } unless exists?(:unicorn_remote_script)

  def unicorn_start_cmd
    "#{unicorn_remote_script} start"
  end

  def unicorn_stop_cmd
    "#{unicorn_remote_script} stop"
  end

  def unicorn_restart_cmd
    "#{unicorn_remote_script} upgrade"
  end

  # Unicorn
  #------------------------------------------------------------------------------
  namespace :unicorn do
    desc "|DarkRecipes| Starts unicorn directly"
    task :start, :roles => :app do
      run unicorn_start_cmd
    end

    desc "|DarkRecipes| Stops unicorn directly"
    task :stop, :roles => :app do
      run unicorn_stop_cmd
    end

    desc "||DarkRecipes|| Restarts unicorn directly"
    task :restart, :roles => :app do
      run unicorn_restart_cmd
    end

    desc <<-EOF
    |DarkRecipes| Parses the configuration file through ERB to fetch our variables and \
    uploads the result to \#{shared_path}/config/unicorn.rb (can be configured via \
    :unicorn_remote_config), to be loaded by whoever is booting up the unicorn.
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      # TODO: refactor this to a more generic setup task once we have more socket tasks.
      commands = []
      commands << "mkdir -p #{sockets_path}"
      commands << "chown #{user}:#{group} #{sockets_path} -R"
      commands << "chmod +rw #{sockets_path}"

      run commands.join(" && ")
      generate_config(unicorn_local_config,unicorn_remote_config)
      generate_config(unicorn_local_script,unicorn_remote_script)
    end

    task :setup_host do
      run "#{sudo} touch #{unicorn_remote_script} && " \
          "#{sudo} chown #{deploy_user}:#{group} #{unicorn_remote_script} && " \
          "#{sudo} chmod u+x #{unicorn_remote_script}"

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
