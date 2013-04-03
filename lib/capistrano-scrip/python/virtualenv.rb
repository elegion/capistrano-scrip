require 'capistrano-scrip/utils'

Capistrano::Configuration.instance.load do
  _cset(:virtualenv_bin) { "virtualenv" }
  _cset(:virtualenv_args) { "--system-site-packages" }
  _cset(:virtualenv_path) { "#{shared_path}/venv" }
  _cset(:python) { "#{virtualenv_path}/bin/python" }
  _cset(:pip_bin) { "#{virtualenv_path}/bin/pip" }

  namespace :virtualenv do
    task :create do
      run "#{virtualenv_bin} #{virtualenv_args} #{virtualenv_path}"
    end

    after 'deploy:setup' do
      virtualenv.create if Capistrano::CLI.ui.agree('Create virtual environment? [y/n]')
    end
  end
end
