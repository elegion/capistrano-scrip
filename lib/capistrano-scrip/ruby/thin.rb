require 'capistrano-scrip/utils'

# Inspired by https://github.com/johnbintz/capistrano-thin
Capistrano::Configuration.instance.load do

  _cset(:thin_command){ 'bundle exec thin' }
  _cset(:thin_local_template) { File.join(templates_path, "thin.yml.erb") }
  _cset(:thin_config_file) { "#{current_path}/config/thin.yml" }
  _cset(:thin_config) { "-C #{thin_config_file}" }

  _cset(:thin_socket) { nil }
  _cset(:thin_port) { 3000 }
  _cset(:thin_pid) { File.join(pids_path, "thin.pid") }
  _cset(:thin_log) { File.join(shared_path, 'log/thin.log') }
  _cset(:thin_max_conns) { 1024 }
  _cset(:thin_max_persistent_conns) { 512 }

  _cset(:thin_servers) { 4 }

  def thin_start_cmd
    "cd #{current_path} && #{thin_command} #{thin_config} start"
  end

  def thin_stop_cmd
    "cd #{current_path} && #{thin_command} #{thin_config} stop"
  end

  def thin_restart_cmd
    "cd #{current_path} && #{thin_command} #{thin_config} -O restart"
  end

  # thin
  #------------------------------------------------------------------------------
  namespace :thin do
    desc "|DarkRecipes| Starts thin directly"
    task :start, :roles => :app do
      run thin_start_cmd
    end

    desc "|DarkRecipes| Stops thin directly"
    task :stop, :roles => :app do
      run thin_stop_cmd
    end

    desc "||DarkRecipes|| Restarts thin directly"
    task :restart, :roles => :app do
      run thin_restart_cmd
    end

    desc <<-EOF
    |DarkRecipes| Parses the configuration file through ERB to fetch our variables and \
    uploads the result to \#{shared_path}/config/thin.rb (can be configured via \
    :thin_config_file), to be loaded by whoever is booting up the thin.
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      # TODO: refactor this to a more generic setup task once we have more socket tasks.
      commands = []
      commands << "mkdir -p #{sockets_path}"
      commands << "chown #{user}:#{group} #{sockets_path} -R"
      commands << "chmod +rw #{sockets_path}"

      run commands.join(" && ")
      generate_config(thin_config_template, thin_config_file)
    end

    task :setup_host do
      with_user deploy_user do
        thin.setup
      end
    end
  end

  namespace :deploy do
    task :restart do
      thin.restart
    end
    task :start do
      thin.start
    end
    task :stop do
      thin.stop
    end
  end

  after 'host:setup' do
    thin.setup_host #if Capistrano::CLI.ui.agree("Create thin run script? [Yn]")
  end
  after 'deploy:setup' do
    thin.setup if !exists?(:deploy_user) && Capistrano::CLI.ui.agree("Create thin configuration file? [Yn]")
  end
end
