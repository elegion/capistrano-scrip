Capistrano::Configuration.instance.load do
  namespace :pip do
    _cset(:pip_bin) { "pip" }
    _cset(:pip_venv_path) { "#{shared_path}/venv" }
    _cset(:pip_requirements_path) { "#{latest_release}/requirements.txt" }
    _cset(:python) { "#{pip_venv_path}/bin/python" }

    task :install do
      run "#{pip_bin} install -E #{pip_venv_path} -sr #{pip_requirements_path} --use-mirrors --mirrors http://f.pypi.python.org"
    end

    after 'deploy:update_code', 'pip:install'
  end
end
