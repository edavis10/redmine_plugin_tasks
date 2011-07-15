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
    method_option :plugin_name, :type => :string, :required => true
    method_option :copyright, :type => :string, :required => true
    method_option :short_desc, :type => :string, :required => true
    method_option :desc, :type => :string, :required => true
    method_option :github_repo, :type => :string, :required => true
    method_option :project, :type => :string, :required => true
    def all
      invoke :gpl2
      invoke :copyright
      invoke :credits
      invoke :readme
      invoke :rakefile
      invoke :gemfile
    end

    desc "gpl2", "generate the GPLv2 license"
    def gpl2
      copy_file 'templates/GPL.txt', "GPL.txt"
    end

    desc "copyright", "generate a copyright file (GPL2)"
    method_option :plugin_name, :type => :string, :required => true
    method_option :copyright, :type => :string, :required => true
    method_option :short_desc, :type => :string, :required => true
    def copyright
      @description = options[:plugin_name] + ' is a plugin that ' + options[:short_desc]
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
    method_option :plugin_name, :type => :string, :required => true
    method_option :project, :type => :string, :default => ''
    method_option :desc, :type => :string, :default => ''
    method_option :github_repo, :type => :string, :default => ''
    def readme
      template("templates/README.rdoc.erb", "README.rdoc")
    end

    desc "rakefile", "generate a Rakefile"
    method_option :plugin_name, :type => :string, :required => true
    method_option :short_desc, :type => :string, :required => true
    method_option :project, :type => :string, :default => ''
    method_option :desc, :type => :string, :default => ''
    def rakefile
      template("templates/Rakefile.erb", "Rakefile")
    end

    desc "gemfile", "generate a Gemfile"
    def gemfile
      template("templates/Gemfile.erb", "Gemfile")
    end
    
    private

    def add_person(people)
      name = ask("What is their name?")
      role = ask("What is their role in the project?")
      people << {:name => name, :role => role}
      people
    end
  end

  class Testing < Base
    desc "test_unit", "generates a basic Test::Unit file structure"
    method_option :integration, :type => :string, :required => true, :default => 'webrat', :desc => 'webrat or capybara'
    def test_unit
      directory 'templates/test', 'test'
      template("templates/test_helper.rb.erb", "test/test_helper.rb")
    end

    desc "autotest", "adds an autotest configuration"
    def autotest
      directory 'templates/autotest', 'autotest'
    end
  end

  class Database < Base
    # TODO: Port over to Rails 3's generators
    
    desc "migration", "generates a migration, using Rail's migration"
    method_option :name, :type => :string, :required => true
    def migration
      template("templates/migration.erb", "db/migrate/xxx_#{options[:name].underscore}.rb")
    end
  end

  class Redmine < Base
    desc "hook", "generates the class and tests to register a Redmine hook"
    method_option :plugin_name, :type => :string, :required => true
    method_option :hook_name, :type => :string, :required => true
    def hook
      template("templates/hook.erb", "lib/#{options[:plugin_name]}/hooks/#{options[:hook_name].underscore}_hook.rb")
      template("templates/hook_test.erb", "test/integration/#{options[:plugin_name]}/hooks/#{options[:hook_name].underscore}_hook_test.rb")

      append_file 'init.rb' do
        "require '#{options[:plugin_name]}/hooks/#{options[:hook_name].underscore}_hook'\n"
      end
    end

    desc "locales", "generates all of the empty locales for i18n"
    def locales
      locales = [:mk, :sr, :ja, :en, :fi, :zh, :ko, :bs, :hu, "pt-BR", :es, :gl, "zh-TW", :pl, :sv, :sl, :th, :fr, :uk, :id, :de, :bg, "sr-YU", :lv, :nl, :tr, :he, :pt, :it, :vi, :ca, :el, :ru, "en-GB", :da, :eu, :lt, :hr, :sk, :mn, :cs, :ro, :no]

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

    desc "copy_locales", "copies the EN locales to the others for i18n"
    def copy_locales
      en_content = File.read("config/locales/en.yml")
      locales = [:mk, :sr, :ja, :en, :fi, :zh, :ko, :bs, :hu, "pt-BR", :es, :gl, "zh-TW", :pl, :sv, :sl, :th, :fr, :uk, :id, :de, :bg, "sr-YU", :lv, :nl, :tr, :he, :pt, :it, :vi, :ca, :el, :ru, "en-GB", :da, :eu, :lt, :hr, :sk, :mn, :cs, :ro, :no]

      locales.each do |locale|
        locale_file = "config/locales/#{locale}.yml"
        unless File.exists?(locale_file)
          create_file locale_file do
            en_content.sub('en', "\"#{locale}\"")
          end
        end
      end
    end

    desc "patch", "generates the modules needed to monkey patch a Redmine core class"
    method_option :plugin_name, :type => :string, :required => true
    method_option :patch_class, :type => :string, :required => true
    def patch
      @class_name = options[:patch_class]
      patch_name = "#{options[:plugin_name].underscore.camelize}::Patches::#{@class_name.underscore.camelize}Patch"
      
      template("templates/patch.erb", "lib/#{options[:plugin_name]}/patches/#{@class_name.underscore}_patch.rb")
      template("templates/patch_test.erb", "test/unit/lib/#{options[:plugin_name]}/patches/#{@class_name.underscore}_patch_test.rb")

      has_dispatcher = false
      File.readlines('init.rb') do |line|
        if line.match(/dispatcher/i)
          has_dispatcher = true
        end
      end

      unless has_dispatcher
        append_file 'init.rb' do
          "require 'dispatcher'\n" +
          "Dispatcher.to_prepare :#{options[:plugin_name]} do\nend"
        end
      end

      inject_into_file 'init.rb', :after => "Dispatcher.to_prepare :#{options[:plugin_name]} do" do
        "\n\n  require_dependency '#{@class_name.underscore}'\n" +
          "  #{@class_name.underscore.camelize}.send(:include, #{patch_name})"
      end
      
    end
  end
end

