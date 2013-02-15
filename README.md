## capistrano-scrip

Bunch of capistrano recipes

Documentation: http://elegion.github.com/capistrano-scrip/
GitHub: https://github.com/elegion/capistrano-scrip

## Installation

Add `capistrano-scrip` to your application's Gemfile:

    gem 'capistrano-scrip', :git => 'git://github.com/glyuck/capistrano-scrip.git'

And then install the bundle:

    $ bundle

## Usage

First, initialize capistrano:

    capify .
    
This will create `./Capfile ` and `./config/deploy.rb`. Edit `./config/deploy.rb` and load recipes required
for your application:

    require "capistrano-scrip/nginx"
    require "capistrano-scrip/mysql"
    require "capistrano-scrip/host"

Then run `cap host:setup deploy:cold` to make your first deploy. Use `cap deploy:migrations` for next deploys.

### Example of rails app deployment

`config/deploy.rb`:

    default_run_options[:pty] = true     # Must be set for the password prompt to work
    set :use_sudo, false                 # Don't use sudo (deploy user must have very limited permissions in system)

    set :default_stage, "staging"        # Deploy on staging server by default

    # Configure capistrano deploy strategy
    set :repository, '.'
    set :deploy_via, :copy
    set :copy_exclude, [".git", "coverage", "results", "tmp", "public/system", "builder"]

    set :root_user, "user"               # User with root privileges on server. You will need him only for host:setup
                                         # and *:setup_host tasks. This will not be used during deploy,
                                         # deploy:migrations and other common tasks.
    set :user, "app_name"                # Deployer user
    set :group, "app_name"               # Deployer group
    set :user_home_path, "/home/www"     # Deployer home on target system (used in host:setup when creating new user)
    set(:deploy_to) { "#{user_home_path}/#{application}" } # Path where to deploy your application

    role(:web) { domain }                         # Your HTTP server, Apache/etc
    role(:app) { domain }                         # This may be the same as your `Web` server
    role(:db, :primary => true) { domain }        # This is where Rails migrations will run

    require "capistrano_colors"                   # Colorized output in console (gem install capistrano_colors)
    require "capistrano/ext/multistage"           # Enable multistage deployment
    require "capistrano-scrip/nginx"              # Use nginx as web-server
    require "capistrano-scrip/mysql"              # Use mysql as db-server
    require "capistrano-scrip/host"               # Require host:setup task
    require "capistrano-scrip/monit"              # Use monit as monitoring system
    require "capistrano-scrip/ruby/thin"          # Use thing as app-server
    require "capistrano-scrip/ruby/rails"         # Load rails-specific recipes
    require "bundler/capistrano"                  # Use bundler on server
    load "deploy/assets"                          # Use rails assets pipeline

`config/deploy/production.rb`

    set :application, "app_name"                  # Application name for production
                                                  # (it's used in some configs and paths)
    set :application_domain, "app_domain.com"     # Domain for production server
    set :domain, "192.168.1.1"                    # Server address where to deploy production

`config/deploy/staging.rb`

    set :application, "app_name_test"             # Application name for staging server
    set :application_domain, "qa.app_domain.com"  # Domain for staging server
    set :domain, "192.168.1.1"                    # Server address where to deploy staging

Then execute `cap host:setup deploy:cold nginx:enable` to create user and config files and perform "cold" deploy,
then symlink `/etc/nginx/sites-available/app_name.conf` to `/etc/nginx/sites-enabled/app_name.conf`.
On next deploy just run `cap deploy:migrations` to deploy new application version.

`cap host:setup` will perform:

 * `host:create_user` - creates `:user` on target system (if doesn't exist yet)
 * `host:ssh_copy_id` - adds `~/.ssh/id_rsa.pub` from local machine to `authorized_keys` on target machine for `:user`
 * Then it performs `*:setup_host` for all loaded recipes:
   * `nginx:setup_host` - creates nginx config file in `/etc/nginx/sites-available/app_name.conf`, grants user
     permissions to modify it. Creates `#{deploy_to}/shared/logs/nginx` directory and grants nginx permissions to
     write there.
   * `mysql:setup_host` - creates mysql user with random password grants him administrative permissions for application
     database (`:database_name`). Then creates `:database_config_template` in `#{deploy_to}/shared/config/database.yml`,
     grants it 440 permissions (only user and group can read it). It will be symlinked to
     `#{deploy_to}/current/config/database.yml` on each deploy.
   * `monit:setup_host` - creates monit config file for thin in `/etc/monit/conf.d/app_name-thin`, grants user
     permissions to modify it.
   * `thin:setup_host` - creates directory for thin sockets (if `:thin_socket` is set), creates thin config file in
     `#{deploy_to}/shared/config/thin.yml`

## Config templates

Capistrano-scrip uses ERB to parse nginx/monit/thin/etc templates. You can see default config templates at github:
https://github.com/elegion/capistrano-scrip/tree/master/templates

If you don't like any of this, you can replace it with you own:

* Put your template in `config/deploy/templates/#{template_name}`
* Or change `*_template` variable value to reflect your template path: `set :monit_config_template, 'deploy/monit.erb'`

## Contributing

1. Fork
2. Create your feature branch (`git checkout -b my_branch`)
3. Commit your changes (`git commit -am "my cool feature"`)
4. Push to the branch (`git push origin my_branch`)
5. Create new Pull Request

### Editing documentation

1. Install dependencies: `bundle install`
2. Run yard server: `bundle exec yard server -r`
3. Edit documentation
4. Preview your changes at http://localhost:8808/
5. Commit: `git commit -am "Updated documentation for ..."
