require 'capistrano-scrip/utils'

Capistrano::Configuration.instance.load do
  namespace :pip do
    _cset(:pip_bin) { "pip" }
    _cset(:pip_requirements_path) { "#{latest_release}/requirements.txt" }

    task :install do
      run "#{pip_bin} install -r #{pip_requirements_path} --use-mirrors --mirrors http://f.pypi.python.org"
    end

    after 'deploy:update_code', 'pip:install'
  end
end
