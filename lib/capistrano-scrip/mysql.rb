require 'securerandom'

Capistrano::Configuration.instance.load do
  set(:database_user) { "#{deploy_user || user}" } unless exists?(:database_user)

  set(:database_name) { "#{application}" } unless exists?(:database_name)
  # Path to the database erb template to be parsed before uploading to remote
  set(:database_local_config) { "#{templates_path}/database.yml.erb" } unless exists?(:database_local_config)

  # Path to where your remote config will reside (I use a directory sites inside conf)
  set(:database_remote_config) do
    "#{shared_path}/config/database.yml"
  end unless exists?(:database_remote_config)

  namespace :db do
    def upload_config
      #password_prompt_with_default :database_password, SecureRandom.urlsafe_base64
      set :database_password, SecureRandom.urlsafe_base64

      run "#{sudo} -u #{deploy_user} mkdir -p #{File.dirname(database_remote_config)} && " \
          "#{sudo} touch #{database_remote_config} && " \
          "#{sudo} chown #{user} #{database_remote_config} && " \
          "#{sudo} chmod 770 #{database_remote_config}"

      generate_config(database_local_config, database_remote_config)

      run "#{sudo} chown #{deploy_user}:#{group} #{database_remote_config} && " \
          "#{sudo} chmod 440 #{database_remote_config}"
    end

    def create_user
      run "echo \"" \
          "CREATE USER \\`#{database_user}\\`@\\`localhost\\` IDENTIFIED BY '#{database_password}';" \
          "CREATE DATABASE \\`#{database_name}\\`;" \
          "GRANT ALL PRIVILEGES ON \\`#{database_name}\\`.* TO \\`#{database_user}\\`;" \
          "\" | #{sudo} mysql -u root"
    end

    def password_prompt_with_default(var, default)
      set(var) do
        Capistrano::CLI.password_prompt "#{var} [#{default}] : "
      end
      set var, default if eval("#{var.to_s}.empty?")
    end

    task :setup_host do
      unless exists?(:deploy_user)
        set :deploy_user, user
        set :user, root_user
      end

      upload_config
      create_user
    end
  end

  after 'host:setup' do
    db.setup_host #if Capistrano::CLI.ui.agree("Create database config? [Yn]")
  end
end

