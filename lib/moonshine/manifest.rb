# This is the base Moonshine Manifest class, which provides a simple system
# for loading moonshine recpies from plugins, a template helper, and parses
# several configuration files:
#
#   config/moonshine.yml
#
# The contents of <tt>config/moonshine.yml</tt> are expected to serialize into
# a hash, and are loaded into the manifest's Configatron::Store.
#
#   config/database.yml
#
# The contents of your database config are parsed and are available at
# <tt>configatron.database</tt>.
#
# If you'd like to create another 'default rails stack' using other tools that
# what Moonshine::Manifest::Rails uses, subclass this and go nuts.
class Moonshine::Manifest < ShadowPuppet::Manifest
  # The working directory of the Rails application this manifests describes.
  def self.working_directory
    @working_directory ||= File.expand_path(ENV["RAILS_ROOT"] || Dir.getwd)
  end

  # Load a Moonshine Plugin
  #
  #   class MyManifest < Moonshine::Manifest
  #
  #     # Evals vendor/plugins/moonshine_my_app/moonshine.init.rb
  #     plugin :moonshine_my_app
  #
  #     # Evals lib/my_recipe.rb
  #     plugin 'lib/my_recipe.rb'
  #
  #     ...
  #   end
  def self.plugin(name = nil)
    if name.is_a?(Symbol)
      path = File.join(working_directory, 'vendor', 'plugins', name.to_s, 'moonshine', 'init.rb')
    else
      path = name
    end
    Kernel.eval(File.read(path), binding, path)
    true
   end

  # Render the ERB template located at <tt>pathname</tt>. If a template exists
  # with the same basename at <p>RAILS_ROOT/app/manifests/templates</p>, it is
  # used instead. This is useful to override templates provided by plugins to
  # customize application configuration files.
  def template(pathname, b = nil)
    b ||= self.send(:binding)
    template_contents = nil
    basename = pathname.index('/') ? pathname.split('/').last : pathname
    if File.exist?(File.expand_path(File.join(self.class.working_directory, 'app', 'manifest', 'templates', basename)))
      template_contents = File.read(File.expand_path(File.join(self.class.working_directory, 'app', 'manifest', 'templates', basename)))
    elsif File.exist?(File.expand_path(pathname))
      template_contents = File.read(File.expand_path(pathname))
    else
      raise LoadError, "Can't find template #{pathname}"
    end
    ERB.new(template_contents).result(b)
  end

  #config/moonshine.yml
  configatron.configure_from_yaml(File.join(working_directory, 'config', 'moonshine.yml'))

  #database config
  configatron.database.configure_from_yaml(File.join(working_directory, 'config', 'database.yml'))

  #gems
  configatron.gems = (YAML.load_file(File.join(working_directory, 'config', 'gems.yml')) rescue nil)
end