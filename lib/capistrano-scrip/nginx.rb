require 'capistrano-scrip/utils'

Capistrano::Configuration.instance.load do
  # Nginx unix-user
  _cset(:nginx_user) { "www-data" }
  # Nginx unix-group
  _cset(:nginx_group) { "www-data" }
  # Where nginx logs will live
  _cset(:nginx_log_path) { "#{shared_path}/log/nginx"}

  # Where your nginx lives. Usually +/etc/nginx+ or +/opt/nginx+ or +/usr/local/nginx+ for source compiled.
  _cset(:nginx_path_prefix) { "/etc/nginx" }
  # Nginx port for your application
  _cset(:nginx_port) { 80 }

  # Path to the nginx erb template to be parsed before uploading to remote
  _cset(:nginx_config_template) { "nginx/nginx_#{app_server}.conf.erb" }

  # Path to where your remote config will reside
  _cset(:nginx_config_path) { "#{nginx_path_prefix}/sites-available/#{application}.conf" }

  # Nginx tasks are not *nix agnostic, they assume you're using Debian/Ubuntu.
  # Override them as needed.
  namespace :nginx do
    desc <<-EOF
    Creates nginx config file on target system, grants user permissions to modify it,
    creates nginx log dir, grants nginx permissions to write there.
    Grants deployer user permissions to perform +service nginx reload+
    EOF
    host_task :setup_host do
      # Create (empty) site config file and allow user to modify it
      run "#{sudo} touch #{nginx_config_path}"
      run "#{sudo} chown #{deploy_user}:#{group} #{nginx_config_path}"
      # Create logs dir and allow nginx to write there
      run "#{sudo} mkdir -p #{nginx_log_path}"
      # We probably just created user home dir, so make sure it belongs to user, not root
      run "#{sudo} chown #{deploy_user}:#{group} -R #{user_home_path}"
      # And nginx logs dir should belong to nginx
      run "#{sudo} chown #{nginx_user}:#{nginx_group} #{nginx_log_path}"
      # Allow user to reload nginx configuration
      sudoers_line = "#{deploy_user} ALL=NOPASSWD: /usr/sbin/service nginx reload\n"
      run "#{sudo} cp /etc/sudoers $TMPDIR/sudoers.tmp && " \
          "echo '\n#{sudoers_line}' | #{sudo} tee -a $TMPDIR/sudoers.tmp && " \
          "#{sudo} visudo -c -f $TMPDIR/sudoers.tmp && " \
          "#{sudo} chmod 0440 $TMPDIR/sudoers.tmp && " \
          "#{sudo} mv $TMPDIR/sudoers.tmp /etc/sudoers"
    end

    desc "Parses and uploads nginx config file for this app."
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(nginx_config_template, nginx_config_path)
    end

    desc "Parses config file and outputs it to STDOUT (internal task)"
    task :parse_config, :roles => :app , :except => { :no_release => true } do
      puts parse_template(nginx_config_template)
    end
    
    desc "Restart nginx (probably deployer user will have no permissions for this task)"
    task :restart, :roles => :app , :except => { :no_release => true } do
      run "#{sudo} service nginx restart"
    end
    
    desc "Reload nginx"
    task :reload, :roles => :app , :except => { :no_release => true } do
      run "#{sudo} service nginx reload"
    end
    
    desc "Stop nginx (probably deployer user will have no permissions for this task)"
    task :stop, :roles => :app , :except => { :no_release => true } do
      run "#{sudo} service nginx stop"
    end
    
    desc "Start nginx (probably deployer user will have no permissions for this task)"
    task :start, :roles => :app , :except => { :no_release => true } do
      run "#{sudo} service nginx start"
    end

    desc "Show nginx status (probably deployer user will have no permissions for this task)"
    task :status, :roles => :app , :except => { :no_release => true } do
      run "service nginx status"
    end
  end

  after 'host:setup' do
    nginx.setup_host #if Capistrano::CLI.ui.agree("Create nginx-related files and folders? [Yn]")
  end
  after 'deploy:setup' do
    nginx.setup
  end
  after "deploy:create_symlink", "nginx:setup", :roles => :app
end

