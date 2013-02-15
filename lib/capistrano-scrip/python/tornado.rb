require 'capistrano-scrip/utils'

Capistrano::Configuration.instance.load do
  namespace :tornado do
    _cset(:app_server) { "tornado" }
    _cset(:python) { "python" }
    _cset(:tornado_script_template) { "tornading.py.erb" }
    _cset(:tornado_script_path) { "/etc/init.d/#{application}.py" }

    task :start do
      run "#{python} #{tornado_script_path} start"
    end
    task :stop do
      run "#{python} #{tornado_script_path} stop"
    end
    task :restart do
      run "#{python} #{tornado_script_path} restart"
    end
    task :setup do
      generate_config(tornado_script_template, tornado_script_path)
    end

    desc "Parses config file and outputs it to STDOUT (internal task)"
    task :parse_script, :roles => :app , :except => { :no_release => true } do
      puts parse_template(tornado_script_template)
    end

    after 'deploy:setup' do
      tornado.setup if Capistrano::CLI.ui.agree("Create tornado run script? [Yn]")
    end
    after 'deploy:symlink', 'tornado:restart'
  end
end
