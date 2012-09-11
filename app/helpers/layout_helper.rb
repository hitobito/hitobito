module LayoutHelper
  

  # Renders all partials with names that match "_#{key}_*.html.haml"
  # in alphabetical order.
  def render_extensions(key, options = {})
      find_extensions(key, options.delete(:folder)).collect do |e|
          render options.merge(:partial => e) 
      end.join
  end        
  
  def find_extensions(key, folder = nil)
      folders = extension_folders
      folders << folder if folder
      extensions = folders.collect do |f|
          view_paths.collect do |path|
              Dir.glob(File.join(path, f, "_#{key}_*.html.haml"))
          end
      end
      extensions = extensions.flatten.sort_by { |f| File.basename(f) }
      extensions.collect do |f|
          m = f.match(/views.(.+?[\/\\])_(.+).html.haml/)
          m[1] + m[2]
      end
  end
  
  def extension_folders
      [controller.controller_path]
  end
    


end