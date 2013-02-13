Capistrano::Configuration.instance.load do
  namespace :deploy do
    task :cold do       # Overriding the default deploy:cold (to run db:setup instead of db:migrate)
      update
      db_setup
      db_seed
      start
    end

    task :db_setup, :roles => :app do
      run "cd #{current_path}; bundle exec rake environment RAILS_ENV=#{rails_env} db:setup"
    end

    task :db_seed, :roles => :app do
      run "cd #{current_path}; bundle exec rake environment RAILS_ENV=#{rails_env} db:seed"
    end
  end

  before "deploy:finalize_update" do
    if exists? :database_config_path
      run "rm -f #{release_path}/config/database.yml && " \
        "ln -s #{database_config_path} #{release_path}/config/database.yml"
    end
  end
end
