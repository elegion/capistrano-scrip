Capistrano::Configuration.instance.load do
  namespace :pip do
    set(:pip_bin, "pip") unless exists?(:pip_bin)
    set(:pip_venv_path) { "#{shared_path}/venv" } unless exists?(:venv_dir)
    set(:pip_requirements_path) { "#{latest_release}/requirements.txt"} unless exists?(:pip_requirements_path)
    set(:python) { "#{pip_venv_path}/bin/python" }

    task :install do
      run "#{pip_bin} install -E #{pip_venv_path} -sr #{pip_requirements_path} --use-mirrors --mirrors http://f.pypi.python.org"
    end
    after 'deploy:update_code', 'pip:install'
  end
end
