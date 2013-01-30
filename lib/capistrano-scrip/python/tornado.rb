Capistrano::Configuration.instance.load do
  namespace :tornado do
    set(:python, "python") unless exists?(:python)
    set(:tornado_local_script) { "#{templates_path}/tornading.py.erb" } unless exists?(:tornado_local_script)
    set(:tornado_remote_script) { "/etc/init.d/#{application}.py"} unless exists?(:tornado_remote_script)

    task :start do
      run "#{python} #{tornado_remote_script} start"
    end
    task :stop do
      run "#{python} #{tornado_remote_script} stop"
    end
    task :restart do
      run "#{python} #{tornado_remote_script} restart"
    end
    task :setup do
      generate_config(tornado_local_script, tornado_remote_script)
    end

    after 'deploy:setup' do
      tornado.setup if Capistrano::CLI.ui.agree("Create tornado run script? [Yn]")
    end
    after 'deploy:symlink', 'tornado:restart'
  end
end
