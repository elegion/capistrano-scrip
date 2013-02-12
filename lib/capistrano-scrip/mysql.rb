require 'securerandom'

Capistrano::Configuration.instance.load do
  _cset(:database_user) { "#{deploy_user || user}" }

  _cset(:database_name) { "#{application}" }
  # Path to the database erb template to be parsed before uploading to remote
  _cset(:database_config_template) { "database.yml.erb" }

  # Path to where your remote config will reside (I use a directory sites inside conf)
  _cset(:database_config_path) {"#{shared_path}/config/database.yml" }

  namespace :db do
    def upload_config
      password_prompt_with_default :database_password, SecureRandom.urlsafe_base64

      run "#{sudo} -u #{deploy_user} mkdir -p #{File.dirname(database_config_path)} && " \
          "#{sudo} touch #{database_config_path} && " \
          "#{sudo} chown #{user} #{database_config_path} && " \
          "#{sudo} chmod 770 #{database_config_path}"

      generate_config(database_config_template, database_config_path)

      run "#{sudo} chown #{deploy_user}:#{group} #{database_config_path} && " \
          "#{sudo} chmod 440 #{database_config_path}"
    end

    def create_db_user
      run "echo \"" \
          "CREATE USER \\`#{database_user}\\`@\\`localhost\\` IDENTIFIED BY '#{database_password}';" \
          "CREATE DATABASE \\`#{database_name}\\`;" \
          "GRANT ALL PRIVILEGES ON \\`#{database_name}\\`.* TO \\`#{database_user}\\`;" \
          "\" | #{sudo} mysql -u root"
    end

    desc "Parses config file and outputs it to STDOUT (internal task)"
    task :parse_config, :roles => :app , :except => { :no_release => true } do
      puts parse_template(database_config_template)
    end

    task :setup_host do
      unless exists?(:deploy_user)
        set :deploy_user, user
        set :user, root_user
      end

      if remote_file_exists?(database_config_path)
        logger.important "Skipping creating DB config, file already exists: #{database_config_path}"
      else
        upload_config
        create_db_user
      end
    end
  end

  after 'host:setup' do
    db.setup_host #if Capistrano::CLI.ui.agree("Create database config? [Yn]")
  end
end

