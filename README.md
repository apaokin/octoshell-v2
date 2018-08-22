# README
Octoshell -  access management system for HPC centers. This project is based on Ruby on Rails framework(4.2)
https://users.parallel.ru/


## Installation and starting

1. install rbenv (https://github.com/rbenv/rbenv)
1. Octoshell is used with 2 ruby implementations: jruby and MRI. Jruby is good in production environment, but boots very slowly. It is significant disadvantage in development environment and you should use MRI implementation during dev. Your code should be compatitible with all implementations.  
To install MRI implementation:
		rbenv install 2.5.1
		rbenv local 2.5.1
To install jruby:
		install jdk (oracle is better).   
		rbenv install jruby-9.1.12.0
		rbenv local jruby-9.1.12.0
1. `gem install bundler`
1. `bundle install`
1. install redis
1. install postgresql
1. `git clone`
1. add database user octo: `sudo -u postgres createuser -s octo`
1. set database password: `sudo -u postgres psql` then enter `\password octo` and enter password. Exit with `\q`.
1. fill database password in `config/database.yml`
1. `bin/rake db:setup`
1. optional run tests: `bin/rspec .`
1. After "seeds" example cluster will be created. You should login to your cluster as root, create new user 'octo'. Login as `admin@octoshell.ru` in web-application. Go to "Admin/Cluster control" and edit "Test cluster". Copy `octo` public key from web to /home/octo/.ssh/authorized_keys.
1. Start production sidekiq: `./run-sidekiq` (`dev-sidekiq` for development)
1. Start production server: `./run` (`dev` for development)
1. Enter as admin with login `admin@octoshell.ru` and password `123456`

## Hacks

### Localization

Currently  Octoshell supports 2 locales: ru (Russian) and en (English). Other locales can be added, but your code should support  at least these 2 locales. "Static" content must be used with `I18n.t` method. Database data is translated using [Traco gem](https://github.com/barsoom/traco). Validation is designed with  `validates_translated` method (`lib/model_translation/active_record_validation.rb`), perfoming validation of data stored in current locale columns.


Users table has the  'language' column. User's working language is stored here. `lib/localized_emails` contains code for emails localization. Email locale depends on user language. If you want to send an email to unregistered user, 'en' locale will be chosen. You can preview your emails with [Rails Email Preview gem](https://github.com/glebm/rails_email_preview).

[I18n-tasks gem](https://github.com/glebm/i18n-tasks) is used to manage locales in the project. But native gem is not designed to work with Rails engines. `lib/relative_keys_extension.rb` extends gem to find missing keys.

### Front-end

javascript libraries: jquery, handlebars, select2 and alpaca.js(for building forms).


We use bootstrap-forms to create static forms. Select2 can build lists using remote data. You can use `autocomplete_field` method  (`engines/face/lib/face/custom_autocomplete_field.rb`) to prepopulate select2 field(if you use remote data.
Example:

		= bootstrap_form_for @search, method: :get, url: admin_users_path, layout: :horizontal do |f|
		  = f.autocomplete_field :id_in,{ label: User.model_name.human, source: main_app.users_path, include_blank: true} do |val|
		    -User.find(val).full_name_with_email ## if id_in is not blank, Selected value will contain all users' full names.

### Notificators

# README
Базовое приложение для модульной версии octoshell.

## Установка и запуск

1. установить rbenv (например `curl https://raw.githubusercontent.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash`)
1. установить jdk (желательно oracle).
1. установить jruby-9.0.5.0 (`rbenv install jruby-9.0.5.0`; `rbenv local jruby-9.0.5.0`)
1. `gem install bundler`
1. `bundle install`
1. установить redis
1. установить postgresql
1. `git clone`
1. добавить пользователя БД octo: `sudo -u postgres createuser -s octo`
1. установить пароль для пользоватедя БД: `sudo -u postgres psql` then enter `\password octo` and enter password. Exit with `\q`.
1. прописать пароль в `config/database.yml`
1. `bin/rake db:setup`
1. запустить тесты (по желанию): `bin/rspec .`
1. После прогона сидов создастся тестовый «кластер». Для синхронизации с ним необходимо доступ на него под пользователем root. Затем залогиниться в приложение как администратор `admin@octoshell.ru`. В «Админке проектов» зайти в раздел «Управление кластерами» и открыть Тестовый кластер. Скопировать публичный ключ админа кластера (по умолчанию `octo`) в /home/octo/.ssh/authorized_keys.
1. Запустить sidekiq: `./run-sidekiq`
1. Запустить сервер: `./run`
1. Войти по адресу `http://localhost:3000/` с логином `admin@octoshell.ru` и паролем `12345`

Процедура деплоя на удалённый серввер сделана через mina: `bundle exec mina deploy`. См. документация на mina.
