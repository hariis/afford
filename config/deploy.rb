set :use_sudo,            false
#tell git to clone only the latest revision and not the whole repository
set :git_shallow_clone,   1
set :keep_releases,       5
set :application,         "afford"
set :user,                "hariis"
set :password,            "mount^hood"
set :deploy_to,           "/home/hariis/afford"
set :runner,              "hariis"
set :repository,          "git@github.com:hariis/afford.git"
set :scm,                 :git

#options necessary to make Ubuntu’s SSH happy
ssh_options[:paranoid]    = false
default_run_options[:pty] = true

role :app, "173.255.211.242"
role :web, "173.255.211.242"
role :db,  "173.255.211.242", :primary => true

namespace :deploy do
  task :start do
    sudo "/etc/init.d/unicorn start"
  end
  task :stop do
    sudo "/etc/init.d/unicorn stop"
  end
  task :restart do
    sudo "/etc/init.d/unicorn reload"
  end
  task :after_symlink, :roles => :app do
   run "ln -nsf #{shared_path}/database.yml #{current_path}/config/database.yml"
   run "ln -nsf #{shared_path}/unicorn.rb #{current_path}/unicorn.rb"
  end
end
