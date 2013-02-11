require 'capistrano-scrip/utils'

# Inspired by https://github.com/johnbintz/capistrano-thin
Capistrano::Configuration.instance.load do

  _cset(:app_server) { "thin" }
  _cset(:thin_command){ 'bundle exec thin' }
  _cset(:thin_config_template) {"thin.yml.erb" }
  _cset(:thin_config_file) { "#{shared_path}/config/thin.yml" }
  _cset(:thin_config) { "-C #{thin_config_file}" }

  _cset(:thin_socket) { nil }
  _cset(:thin_port) { 3000 }
  _cset(:thin_pid) { "#{shared_path}/pids/thin.pid" }
  _cset(:thin_log) { "#{shared_path}/log/thin.log" }
  _cset(:thin_max_conns) { 1024 }
  _cset(:thin_max_persistent_conns) { 512 }

  _cset(:thin_servers) { 4 }

  def thin_socket_for_server(number)
    thin_socket.sub(/\.sock$/, ".#{number+1}.sock")
  end

  def thin_port_for_server(number)
    thin_port + number
  end

  def thin_pid_for_server(number)
    thin_pid.sub(/\.pid$/, ".#{thin_socket ? number : thin_port_for_server(number)}.pid")
  end

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
      create_remote_dir(File.dirname(thin_socket)) if thin_socket

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
    thin.setup
  end
  after "deploy:create_symlink", "thin:setup", :roles => :app
end
