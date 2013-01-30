Capistrano::Configuration.instance.load do
  namespace :django_fcgi do
    set(:python, "python") unless exists?(:python)
    set(:django_fcgi_local_script) { "#{templates_path}/django_fcgi.sh.erb" } unless exists?(:django_fcgi_local_script)
    set(:django_fcgi_remote_script) { "/etc/init.d/#{application}.sh"} unless exists?(:django_fcgi_remote_script)
    set(:django_fcgi_socket_path) {"#{sockets_path}/django_fcgi.sock"} unless exists?(:django_fcgi_socket_path)
    set(:django_fcgi_pid_path) {"#{pids_path}/django_fcgi.pid"} unless exists?(:django_fcgi_pid_path)

    task :setup_host do
      script_name = File.basename django_fcgi_remote_script
      # Create fcgi script, allow user to modify it
      run "#{sudo} touch #{django_fcgi_remote_script}"
      run "#{sudo} chown #{deploy_user}:#{group} #{django_fcgi_remote_script}"
      run "#{sudo} chmod u+x #{django_fcgi_remote_script}"
      # Run fcgi script on system startup
      run "#{sudo} update-rc.d -f #{script_name} start 99 2 3 4 5 ."
      run "#{sudo} update-rc.d -f #{script_name} stop 99 0 6 ."
    end

    task :start do
      run "#{django_fcgi_remote_script} start"
    end
    task :restart do
      run "#{django_fcgi_remote_script} restart"
    end
    task :stop do
      run "#{django_fcgi_remote_script} stop"
    end
    task :setup do
      generate_config(django_fcgi_local_script, django_fcgi_remote_script)
    end
  end

  after 'host:setup' do
    django_fcgi.setup_host if Capistrano::CLI.ui.agree("Create fcgi-related files? [Yn]")
  end
  after 'deploy:setup' do
    django_fcgi.setup if Capistrano::CLI.ui.agree("Create fcgi run script? [Yn]")
  end
  after 'deploy:symlink', 'django_fcgi:restart'
end
