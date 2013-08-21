require 'google/api_client'
require 'mime/types'

class Worochi
  # The {Agent} for Google Drive API.
  # @see https://github.com/google/google-api-ruby-client
  class Agent::GoogleDrive < Agent

    # Initializes the Google Drive API client.
    #
    # @return [ApiClient]
    # @see Agent#initialize
    def init_client
      @id_cache = {}
      disable_write
      @client = Google::APIClient.new(
        application_name: 'Worochi',
        application_version: Worochi::VERSION)
      @client.authorization.access_token = options[:token]
      @drive = @client.discovered_api('drive', 'v2')
      @client
    end

    # Pushes multiple items to Google Drive.
    #
    # @return [Array<String>] list of resource IDs of the uploaded files
    def push_all(items)
      items.map { |item| push_item(item) }
    end

    # Pushes an individual item to the service. Usually a service-specific
    # implementation should only need one of either {#push_item} or
    # {#push_all}.
    #
    # @return [nil]
    # @see Agent#push_items
    def push_item(item)
      # TODO
      enable_write
      abs_path = full_path(item.path)
      parent_id = get_parent_id(abs_path)
      disable_write
      # @client.push(item.content, item.path)
    end

    # Returns a list of files and subdirectories at the remote path specified
    # by `options[:dir]`.
    #
    # @param path [String] path to list instead of the current directory
    # @return [Array<Hash>] list of files and subdirectories
    def list(path=nil)
      remote_path = list_path(path)
      result = navigate_to(remote_path)
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
          gdrive_id: elem.id
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
      response = @client.execute(
        api_method: @drive.files.delete,
        parameters: { 'fileId' => item_id })
      response.status == 200
    end

  private
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

    def get_parent_id(abs_path)
      parent_path = File.dirname(abs_path)
      get_item_id(parent_path)
    end

    # @param abs_path [String] absolute path to the item
    # @return [String] Google Drive source ID for the item
    def get_item_id(abs_path)
      return @id_cache[abs_path] if @id_cache.include?(abs_path)

      file_name = File.basename(abs_path)
      folder_path = File.dirname(abs_path)
      return 'root' if ['/', '.', ''].include?(file_name)

      parent_items = navigate_to(folder_path)
      item = find_item_by_name(parent_items, file_name)
      return nil if item.nil?

      @id_cache[abs_path] = item.id
      item.id
    end

    # @return [String] resource ID of the created file
    def insert_file(title, parent_id, item=nil)
      body = { 'title' => title, 'parents' => { 'id' => parent_id }}
      opts = { api_method: @drive.files.insert }

      if item
        opts[:parameters] = { 'uploadType' => 'resumable' }
        opts[:media] = Google::APIClient::UploadIO.new(item.content,
          item.content_type, item.content.path)
      else
        body['mimeType'] = 'application/vnd.google-apps.folder'
      end

      opts[:body_object] = @drive.files.insert.request_schema.new(body)

      response = @client.execute(opts)
      if item
        retries = 0
        while !response.resumable_upload.complete? && retries < 10
          retries++
          response = @client.execute(response.resumable_upload)
        end
      end

      response.status == 200 ? response.data.id : nil
    end

    # List the files and folders at the target absolute path.
    #
    # @param path [String] absolute path
    # @return [Array<Google::APIClient::Schema::Drive::V2::File>] children
    def navigate_to(abs_path)
      folders = abs_path.split('/').reject(&:empty?)
      get_folder_items(folders, 'root')
    end

    # Recursively navigate to the target folder.
    #
    # @param folders [Array<String>] list of folder names
    # @return [Array<Google::APIClient::Schema::Drive::V2::File>] children
    def get_folder_items(folders, parent_id)
      items = retrieve_items(parent_id)
      return items if folders.empty?

      name = folders.shift
      item = find_item_by_name(items, name)
      if item
        item_id = item.id
      else
        raise Error, 'Invalid path specified' unless write?
        item_id = insert_file(name, parent_id)
      end

      get_folder_items(folders, item_id)
    end

    # Returns a single item from a list of items by matching its file name.
    #
    # @param items [Array<Google::APIClient::Schema::Drive::V2::File>] items
    # @param name [String] file name
    # @return [Google::APIClient::Schema::Drive::V2::File]
    def find_item_by_name(items, name)
      index = items.find_index { |elem| elem.title == name }
      index.nil? ? nil : items[index]
    end

    # Retrieves all the children of the specified directory.
    #
    # @param id [String] Google Drive resource ID of the directory
    # @return [Array<Google::APIClient::Schema::Drive::V2::File>] children
    def retrieve_items(id)
      fields = 'items(id,mimeType,title),nextPageToken'
      q = "'#{id}' in parents"
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