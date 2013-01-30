Capistrano::Configuration.instance.load do
  namespace :django do
    set(:python) { "python" } unless exists?(:python)

    task :collectstatic do
      run "#{python} #{latest_release}/manage.py collectstatic --noinput"
    end

    task :manage do
      if ENV.has_key?('command')
        run "cd #{latest_release}; #{python} manage.py #{ENV['command']}"
      else
        ui.say "Please specify command to run: cap django:manage command=syncdb"
      end
    end

    task :createsuperuser do
      ask_with_default :su_username, "root"
      password_prompt_with_default :su_password, "123123"
      ask_with_default :su_email, "#{su_username}@mailinator.com"
      run "cd #{latest_release}; #{python} manage.py createsuperuser",
        :data => "#{su_username}\n#{su_email}\n#{su_password}\n#{su_password}\n",
        # Disable pty, so python's getpass will read pass from stdin
        :pty => false
    end

    def ask_with_default(var, default)
      set(var) do
        Capistrano::CLI.ui.ask "#{var} [#{default}] : "
      end
      set var, default if eval("#{var.to_s}.empty?")
    end

    def password_prompt_with_default(var, default)
      set(var) do
        Capistrano::CLI.password_prompt "#{var} [#{default}] : "
      end
      set var, default if eval("#{var.to_s}.empty?")
    end

  end

  after 'deploy:update_code', 'django:collectstatic'
end
