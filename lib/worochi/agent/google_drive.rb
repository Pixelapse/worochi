require 'google/api_client'
require 'awesome_print'

class Worochi
  # The {Agent} for Google Drive API.
  # @see https://github.com/google/google-api-ruby-client
  class Agent::GoogleDrive < Agent

    # Initializes the Google Drive API client.
    #
    # @return [ApiClient]
    # @see Agent#initialize
    def init_client
      clear_cache
      disable_write
      @client = Google::APIClient.new(
        application_name: 'Worochi',
        application_version: Worochi::VERSION)
      @client.authorization.access_token = options[:token]
      @drive = @client.discovered_api('drive', 'v2')
      @client
    end

    # Pushes an individual item to Google Drive.
    #
    # @return [String] resource ID of the uploaded file.
    def push_item(item)
      enable_write
      abs_path = full_path(item.path)
      parent_id = get_parent_id(abs_path)
      id = insert_file(item, parent_id)
      disable_write
      id
    end

    # Returns a list of files and subdirectories at the remote path specified
    # by `options[:dir]`.
    #
    # @param path [String] path to list instead of the current directory
    # @return [Array<Hash>] list of files and subdirectories
    def list(path=nil)
      remote_path = list_path(path)
      result, folder_id = navigate_to(remote_path)
      result.map do |elem|
        if elem.mimeType == 'application/vnd.google-apps.folder'
          file_type = 'folder'
        else
          file_type = 'file'
        end
        {
          name: elem.title,
          path: File.join(remote_path, elem.title),
          type: file_type,
          id: elem.id,
          parent_id: folder_id
        }
      end
    end

    # Deletes the file at `path` from Google Drive.
    #
    # @param path [String] path relative to current directory
    # @return [Boolean] `true` if a file was actually deleted
    def delete(path)
      abs_path = full_path(path)
      item_id = get_item_id(abs_path)
      return false if item_id.nil?
      delete_by_id(item_id)
    end

    # Clears the internal resource ID cache
    def clear_cache
      @id_cache = {}
    end

  private
    # Saves a resource ID in the cache.
    #
    # @param abs_path [String] absolute path to the file/folder
    # @param id [String] resource ID of the file/folder
    # @return [nil]
    def set_cache(abs_path, id)
      abs_path ='/' if abs_path == ''
      @id_cache[abs_path] = { id: id, time: Time.now }
      nil
    end

    # Retrieves a saved cache entry.
    #
    # @param abs_path [String] absolute path to the file/folder
    # @return [String] resource ID of the file/folder
    def get_cached(abs_path)
      return nil unless @id_cache.include?(abs_path)
      @id_cache[abs_path][:id]
    end

    # Recursive directory lookup automatically creates missing directories.
    def enable_write
      @write = true
    end

    # Disable auto-creation of missing directories.
    def disable_write
      @write = false
    end

    # @return [Boolean] `true` if auto-creation is enabled.
    def write?
      @write
    end

    # @param id [String] resource ID of file/folder to be deleted
    # @return [Boolean] successfully deleted
    def delete_by_id(id)
      response = @client.execute(
        api_method: @drive.files.delete,
        parameters: { 'fileId' => id })
      response.status == 204
    end

    # @param abs_path [String] absolute path of the child
    # @return [String] parent resource ID
    def get_parent_id(abs_path)
      parent_path = File.dirname(abs_path)
      get_item_id(parent_path)
    end

    # @param abs_path [String] absolute path to the item
    # @return [String] Google Drive source ID for the item
    def get_item_id(abs_path)
      return get_cached(abs_path) if get_cached(abs_path)

      file_name = File.basename(abs_path)
      folder_path = File.dirname(abs_path)
      return 'root' if ['/', '.', ''].include?(file_name)

      parent_items, parent_id = navigate_to(folder_path)
      item = find_item_by_name(parent_items, file_name)
      if item
        item_id = item.id
      else
        item_id = write? ? insert_file(file_name, parent_id) : nil
      end

      set_cache(abs_path, item_id)
      item_id
    end

    # Uploads files or creates new directories.
    #
    # @overload insert_file(title, parent_id)
    #   @param title [String] new directory name
    #   @param parent_id [String] parent resource ID
    # @overload insert_file(item, parent_id)
    #   @param item [Worochi::Item] file to be uploaded
    #   @param parent_id [String] parent resource ID
    # @return [String] resource ID of the created file
    def insert_file(arg, parent_id)
      if arg.respond_to?(:filename)
        item = arg
        title = arg.filename
      else
        item = false
        title = arg
      end

      body = { 'title' => title, 'parents' => [{ 'id' => parent_id }]}
      opts = { api_method: @drive.files.insert }

      if item
        opts[:parameters] = { 'uploadType' => 'resumable' }
        opts[:media] = Google::APIClient::UploadIO.new(item.content,
          item.content_type, item.content.path)
      else
        body['mimeType'] = 'application/vnd.google-apps.folder'
      end

      opts[:body_object] = @drive.files.insert.request_schema.new(body)

      begin
        response = @client.execute(opts)
      rescue NoMethodError
        # Google API client does not fail correctly given an invalid token
        # Need to catch and handle it here
        raise Error, 'Google Error: Invalid credentials'
      end

      # if item
      #   retries = 0
      #   while !response.resumable_upload.complete? && retries < 10
      #     retries += 1
      #     sleep(rand(6))
      #     ap "retry #{retries}"
      #     response = @client.execute(response.resumable_upload)
      #   end
      # end

      response.data ? response.data.id : nil
    end

    # List the files and folders at the target absolute path.
    #
    # @param abs_path [String] absolute path
    # @return [Array<Google::APIClient::Schema::Drive::V2::File>] children
    def navigate_to(abs_path)
      folders = abs_path.split('/').reject(&:empty?)
      get_folder_items(folders)
    end

    # Recursively navigate to the target folder.
    #
    # @param folders [Array<String>] list of folder names
    # @param parent_id [String] parent resource ID
    # @param curr_path [String] absolute path to current parent
    # @return [Array<Google::APIClient::Schema::Drive::V2::File>, String]
    #   children list and resource ID of parent
    def get_folder_items(folders, parent_id='root', curr_path='')
      set_cache(curr_path, parent_id)
      items = retrieve_items(parent_id)
      return items, parent_id if folders.empty?

      name = folders.shift
      item = find_item_by_name(items, name)
      if item
        item_id = item.id
      else
        raise Error, 'Invalid path specified' unless write?
        item_id = insert_file(name, parent_id)
      end

      get_folder_items(folders, item_id, "#{curr_path}/#{name}")
    end

    # Returns a single item from a list of items by matching its file name.
    #
    # @param items [Array<Google::APIClient::Schema::Drive::V2::File>] items
    # @param name [String] file name
    # @return [Google::APIClient::Schema::Drive::V2::File]
    def find_item_by_name(items, name)
      found = items.select { |elem| elem.title == name }
      raise Error, "Ambiguous file name #{name}" if found.size > 1
      found.first
    end

    # Retrieves all the children of the specified directory.
    #
    # @param id [String] Google Drive resource ID of the directory
    # @return [Array<Google::APIClient::Schema::Drive::V2::File>] children
    def retrieve_items(id)
      fields = 'items(id,mimeType,title),nextPageToken'
      q = "'#{id}' in parents and trashed = false"
      page_token = nil
      result = []
      begin
        params = { 'q' => q, 'fields' => fields }
        params['pageToken'] = page_token unless page_token.to_s == ''
        response = @client.execute(
          api_method: @drive.files.list,
          parameters: params)
        if response.status == 200
          elems = response.data
          result.concat(elems.items)
          page_token = elems.next_page_token
        else
          error_msg = response.data['error']['message']
          raise Worochi::Error, "Google Error: #{error_msg}"
        end
      end while page_token.to_s != ''
      result
    end
  end
end