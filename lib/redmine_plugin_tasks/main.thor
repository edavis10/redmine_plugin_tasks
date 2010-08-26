# module: redmine_plugin_tasks
require 'active_support'

module RedminePluginTasks
  class Base < Thor
    include Thor::Actions

    def self.source_root
      File.dirname(__FILE__)
    end
  end

  class Docs < Base
    desc "all", "Generate all docs for a new plugin"
    def all
      ask_basic_questions

      invoke :gpl2
      invoke :copyright
      invoke :credits
      invoke :readme
      invoke :rakefile
    end

    desc "gpl2", "generate the GPLv2 license"
    def gpl2
      copy_file 'templates/GPL.txt', "GPL.txt"
    end

    desc "copyright", "generate a copyright file (GPL2)"
    def copyright
      ask_basic_questions
      @description = @plugin_name + ' is a plugin that ' + @plugin_short_description
      template("templates/COPYRIGHT.erb", "COPYRIGHT.txt")
    end

    desc "credits", "generate a Credits file"
    def credits
      @people = []
      while yes?("Add a person?", :green)
        add_person(@people)
      end

      template("templates/CREDITS.erb", "CREDITS.txt")

    end

    desc "readme", "generate a Readme"
    def readme
      ask_basic_questions
      template("templates/README.rdoc.erb", "README.rdoc")
    end

    desc "rakefile", "generate a Rakefile"
    def rakefile
      ask_basic_questions
      template("templates/Rakefile.erb", "Rakefile")
    end
    
    private

    def ask_basic_questions
      @plugin_name ||= ask("What is the plugin name?")
      @plugin_short_description ||= ask("What does the plugin do (short)?")
      @plugin_description ||= ask("What does the plugin do (long)?")
      @copyright_holder ||= ask("Who is the copyright holder?")
      @redmine_project ||= ask("What is the Redmine project identifier?")
      @github_repo ||= ask("What is the Github repo called?")
    end
    
    def add_person(people)
      name = ask("What is their name?")
      role = ask("What is their role in the project?")
      people << {:name => name, :role => role}
      people
    end
  end

  class Testing < Base
    desc "test_unit", "generates a basic Test::Unit file structure"
    def test_unit
      directory 'templates/test', 'test'
    end

    desc "autotest", "adds an autotest configuration"
    def autotest
      directory 'templates/autotest', 'autotest'
    end
  end

  class Database < Base
    # TODO: Port over to Rails 3's generators
    
    desc "migration", "generates a migration, using Rail's migration"
    def migration(name)
      @name = name
      template("templates/migration.erb", "db/migrate/xxx_#{@name.underscore}.rb")
    end
  end

  class Redmine < Base
    desc "hook", "generates the class and tests to register a Redmine hook"
    def hook(name)
      @plugin_name = ask("What is the plugin name?")
      @hook_name = name
      @hook_name ||= ask("What hook do you want to use?")

      template("templates/hook.erb", "lib/#{@plugin_name}/hooks/#{@hook_name.underscore}_hook.rb")
      template("templates/hook_test.erb", "test/integration/#{@plugin_name}/hooks/#{@hook_name.underscore}_hook_test.rb")

      append_file 'init.rb' do
        "require '#{@plugin_name}/hooks/#{@hook_name.underscore}_hook'\n"
      end
    end

    desc "locales", "generates all of the empty locales for i18n"
    def locales
      locales = [:sr, :ja, :en, :fi, :zh, :ko, :bs, :hu, "pt-BR", :es, :gl, "zh-TW", :pl, :sv, :sl, :th, :fr, :uk, :id, :de, :bg, :nl, :tr, :he, :pt, :it, :vi, :ca, :el, :ru, :da, :eu, :lt, :hr, :sk, :cs, :ro, :no]

      locales.each do |locale|
        locale_file = "config/locales/#{locale}.yml"
        unless File.exists?(locale_file)
          create_file locale_file do
            "\"#{locale}\":\n" +
              "  test_field: Test"
          end
        end
      end
    end

    desc "patch", "generates the modules needed to monkey patch a Redmine core class"
    def patch(class_name)
      @plugin_name = ask("What is the plugin name?")
      @class_name = class_name
      patch_name = "#{@plugin_name.underscore.camelize}::Patches::#{@class_name.underscore.camelize}Patch"
      
      template("templates/patch.erb", "lib/#{@plugin_name}/patches/#{@class_name.underscore}_patch.rb")
      template("templates/patch_test.erb", "test/unit/lib/#{@plugin_name}/patches/#{@class_name.underscore}_patch_test.rb")

      has_dispatcher = false
      File.readlines('init.rb') do |line|
        if line.match(/dispatcher/i)
          has_dispatcher = true
        end
      end

      unless has_dispatcher
        append_file 'init.rb' do
          "require 'dispatcher'\n" +
          "Dispatcher.to_prepare :#{@plugin_name} do\nend"
        end
      end

      inject_into_file 'init.rb', :after => "Dispatcher.to_prepare :#{@plugin_name} do" do
        "\n\n  require_dependency '#{@class_name.underscore}'\n" +
          "  #{@class_name.underscore.camelize}.send(:include, #{patch_name})"
      end
      
    end
  end
end

