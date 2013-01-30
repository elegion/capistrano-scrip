Capistrano::Configuration.instance.load do
  set :nginx_user, "www-data" unless exists?(:nginx_user)
  set :nginx_group, "www-data" unless exists?(:nginx_group)
  set(:nginx_log_path) { "#{shared_path}/log/nginx"} unless exists?(:nginx_log_path)

  # Where your nginx lives. Usually /opt/nginx or /usr/local/nginx for source compiled.
  set :nginx_path_prefix, "/opt/nginx" unless exists?(:nginx_path_prefix)

  # Path to the nginx erb template to be parsed before uploading to remote
  set(:nginx_local_config) { "#{templates_path}/nginx.conf.erb" } unless exists?(:nginx_local_config)

  # Path to where your remote config will reside (I use a directory sites inside conf)
  set(:nginx_remote_config) do
    "#{nginx_path_prefix}/conf/sites/#{application}.conf"
  end unless exists?(:nginx_remote_config)

  # Nginx tasks are not *nix agnostic, they assume you're using Debian/Ubuntu.
  # Override them as needed.
  namespace :nginx do
    desc "|DarkRecipes| Parses and uploads nginx configuration for this app."
    task :setup_host do
      # Create (empty) site config file and allow user to modify it
      run "#{sudo} touch #{nginx_remote_config}"
      run "#{sudo} chown #{deploy_user}:#{group} #{nginx_remote_config}"
      # Create logs dir and allow nginx to write there
      run "#{sudo} mkdir -p #{nginx_log_path}"
      # We probably just created user home dir, so make sure it belongs to user, not root
      run "#{sudo} chown #{deploy_user}:#{group} -R #{user_home_path}"
      # And nginx logs dir should belong to nginx
      run "#{sudo} chown #{nginx_user}:#{nginx_group} #{nginx_log_path}"
      # Allow user to reload nginx configuration
      sudoers_line = "\n#{deploy_user} ALL=NOPASSWD: /usr/sbin/service nginx reload\n"
      run "#{sudo} cp /etc/sudoers $TMPDIR/sudoers.tmp && " \
          "echo '#{sudoers_line}' | #{sudo} tee -a $TMPDIR/sudoers.tmp && " \
          "#{sudo} visudo -c -f $TMPDIR/sudoers.tmp && " \
          "#{sudo} chmod 0440 $TMPDIR/sudoers.tmp && " \
          "#{sudo} mv $TMPDIR/sudoers.tmp /etc/sudoers"
    end
    task :setup, :roles => :app , :except => { :no_release => true } do
      generate_config(nginx_local_config, nginx_remote_config)
    end
    
    desc "|DarkRecipes| Parses config file and outputs it to STDOUT (internal task)"
    task :parse, :roles => :app , :except => { :no_release => true } do
      puts parse_config(nginx_local_config)
    end
    
    desc "|DarkRecipes| Restart nginx"
    task :restart, :roles => :app , :except => { :no_release => true } do
      run "#{sudo} service nginx restart"
    end
    
    desc "|DarkRecipes| Reload nginx"
    task :reload, :roles => :app , :except => { :no_release => true } do
      run "#{sudo} service nginx reload"
    end
    
    desc "|DarkRecipes| Stop nginx"
    task :stop, :roles => :app , :except => { :no_release => true } do
      run "#{sudo} service nginx stop"
    end
    
    desc "|DarkRecipes| Start nginx"
    task :start, :roles => :app , :except => { :no_release => true } do
      run "#{sudo} service nginx start"
    end

    desc "|DarkRecipes| Show nginx status"
    task :status, :roles => :app , :except => { :no_release => true } do
      run "#{sudo} service nginx status"
    end
  end

  after 'host:setup' do
    nginx.setup_host #if Capistrano::CLI.ui.agree("Create nginx-related files and folders? [Yn]")
  end
  after 'deploy:setup' do
    nginx.setup if !exists?(:deploy_user) && Capistrano::CLI.ui.agree("Create nginx configuration file? [Yn]")
  end
end

