class Hammer
  class HammerFile
    attr_accessor :cached
  end
end

class Hammer
  class Cacher
    
    # Start this off with a hammer_project. It belongs to the project.
    def initialize(hammer_project, directory)
      @directory = directory
      @hammer_project = hammer_project
      @hard_dependencies = {}
      
      @new_hashes = {}
      @new_dependency_hash = {}
      @new_hard_dependencies = {}
      
      read_from_disk
    end
    

    def read_from_disk
      @dependency_hash = {}
      @hashes = {}
      
      return true unless @directory
      path = File.join(@directory, "cache.json")
      if File.exists? path
        contents = File.open(path).read
        if contents && contents != ""
          contents = JSON.parse(contents)
          @dependency_hash = contents['dependency_hash'] if contents['dependency_hash']
          @hard_dependencies = contents['hard_dependencies'] if contents['hard_dependencies']
          @new_dependency_hash = @dependency_hash
          @hashes = contents['hashes'] if contents['hashes']
        end
      end
    end

    # When finished:
    def write_to_disk
      
      @dependency_hash = @new_dependency_hash
      @hashes = @new_hashes
      @hard_dependencies = @new_hard_dependencies
      
      contents = {:dependency_hash => @dependency_hash, :hashes => @hashes, :hard_dependencies => @hard_dependencies}
      
      return true unless @directory
      path = File.join(@directory, "cache.json")
      
      FileUtils.mkdir_p File.dirname(path)
      File.open(path, "w") do |f|     
        f.write contents.to_json
      end
    end
    
    
    def cached_contents_for(path)
      path = File.join(@directory, path)
      FileUtils.mkdir_p File.dirname(path)
      File.open(path).read
    rescue
      nil
    end
    
    def set_cached_contents_for(path, contents)
      path = File.join(@directory, path)
      FileUtils.mkdir_p File.dirname(path)
      File.open(path, "w") do |f|
        f.write(contents)
      end
    end

    def needs_recompiling_without_cache(path)
      
      @new_hashes[path] ||= hash(path)
      new_hash = @new_hashes[path]
      
      # # Yes if the file is modified.
      if new_hash != @hashes[path]
        # puts "File #{path} is modified from #{@hashes[path]} to #{new_hash}!"
        @new_dependency_hash[path] = nil
        return true 
      end
    
    
      if @hard_dependencies[path]
        @hard_dependencies[path].each do |dependency|
          next if dependency == path
          if needs_recompiling?(dependency)
            return true 
          end
        end
      end
      
      if @dependency_hash[path]
        
        # Yes if the file's references have changed (new files).
        @dependency_hash[path].each_pair do |query, matches|
          
          matches.each do |type, filenames|
            next if query.nil?
            new_results = @hammer_project.find_files(query, type).collect(&:filename)
            if new_results != filenames
              # puts "File #{path}'s references have changed: #{query} is now #{new_results} instead of #{filenames}"
              return true
            end
        #   end
          
        # # end

        # # # Yes if any dependencies need recompiling. 
        # # @dependency_hash[path].each_pair do |type, matches|
        #   matches.each do |query, filenames|
            next if query.nil?
            files = @hammer_project.find_files(query, type)
            @hammer_project.find_files(query, type).each do |file|
              sub_file_path = file.filename
              if needs_recompiling?(sub_file_path)
                return true 
              end
            end
          end
        end
        
      end
      
      # File #{path} was not modified.
      return false
      
    end
    
    # Check a file to see whether it needs recompiling.
    def needs_recompiling?(path)
      
      
      @needs_recompiling ||= {}
      if @needs_recompiling[path] != nil
        result = @needs_recompiling[path]
      else
        result = needs_recompiling_without_cache(path)
        @needs_recompiling[path] = result
      end
      
      if !result
        @new_hard_dependencies[path] = @hard_dependencies[path]
      end
      return result
    end
    
    def add_wildcard_dependency(path, query, type)
      begin
        results = @hammer_project.find_files(query, type).collect(&:filename)
        results -= [path]
        @new_dependency_hash[path] ||= {}
        @new_dependency_hash[path][query] ||= {}
        @new_dependency_hash[path][query][type] ||= results
      rescue => e
        puts e.message
        puts e.backtrace
      end
    end
    
    def add_file_dependency(file_path, dependency_path)
      @new_hard_dependencies[file_path] ||= []
      @new_hard_dependencies[file_path] << dependency_path
    end
    
  private
    
    # TODO: CHange this from reading the whole file.
    # We may be able to do this with timestamps instead. Might be a better approach.
    def hash(path)
      return nil unless @hammer_project.input_directory
      full_path = File.join(@hammer_project.input_directory, path)
      md5 = Digest::MD5.file(full_path).hexdigest
    rescue
      nil
    end
    
  end
end