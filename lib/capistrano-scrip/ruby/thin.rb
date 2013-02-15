require 'capistrano-scrip/utils'

# Use thin as application server (inspired by https://github.com/johnbintz/capistrano-thin)
#
# Thin is a Ruby web server built on top of Event Machine, a network I/O library with extremely high scalability,
# performance and stability.
Capistrano::Configuration.instance.load do
  # App server type, you normally shouldn't change this
  _cset(:app_server) { "thin" }
  # Command to execute for running thin
  _cset(:thin_command){ 'bundle exec thin' }
  # Path to thing configuration template
  _cset(:thin_config_template) {"thin.yml.erb" }
  # Remote location of thin config template
  _cset(:thin_config_file) { "#{shared_path}/config/thin.yml" }
  # Default arguments for thin command
  _cset(:thin_arguments) { "-C #{thin_config_file}" }

  # Path to thin socket file. If nil, TCP port will be used. You can use something like
  # +#{shared_path}/socket/thin.sock+
  _cset(:thin_socket) { nil }
  # TCP port to use with thin (not used if :thin_socket is set)
  _cset(:thin_port) { 3000 }
  # Path to thin pid file
  _cset(:thin_pid) { "#{shared_path}/pids/thin.pid" }
  # Path to thin log file
  _cset(:thin_log) { "#{shared_path}/log/thin.log" }
  # Max concurrent connections can be handled by thin
  # Setting higher then 1024 might require superuser privileges on some system.
  _cset(:thin_max_conns) { 1024 }
  # Max persistent connections can be handled by thin
  _cset(:thin_max_persistent_conns) { 512 }
  # Number of thin instances to run
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
    "cd #{current_path} && #{thin_command} #{thin_arguments} start"
  end

  def thin_stop_cmd
    "cd #{current_path} && #{thin_command} #{thin_arguments} stop"
  end

  def thin_restart_cmd
    "cd #{current_path} && #{thin_command} #{thin_arguments} -O restart"
  end

  # thin
  #------------------------------------------------------------------------------
  namespace :thin do
    desc "Starts thin directly"
    task :start, :roles => :app do
      run thin_start_cmd
    end

    desc "Stops thin directly"
    task :stop, :roles => :app do
      run thin_stop_cmd
    end

    desc "Restarts thin directly"
    task :restart, :roles => :app do
      run thin_restart_cmd
    end

    desc "Parses config file and outputs it to STDOUT (internal task)"
    task :parse_config, :roles => :app , :except => { :no_release => true } do
      puts parse_template(thin_config_template)
    end

    desc <<-EOF
    Parses the configuration file through ERB to fetch our variables and \
    uploads the result to +\#{shared_path}/config/thin.rb+ (can be configured via \
    +:thin_config_file+), to be loaded by whoever is booting up the thin.
    EOF
    task :setup, :roles => :app , :except => { :no_release => true } do
      # TODO: refactor this to a more generic setup task once we have more socket tasks.
      create_remote_dir(File.dirname(thin_socket)) if thin_socket

      generate_config(thin_config_template, thin_config_file)
    end

    desc "Creates thin config on server."
    host_task :setup_host do
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
