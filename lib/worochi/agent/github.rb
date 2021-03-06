require 'octokit'
require 'base64'

class Worochi
  # The {Agent} for GitHub API. This wraps around the `octokit` gem.
  # @see https://github.com/octokit/octokit.rb
  class Agent::Github < Agent
    # Initializes Octokit client. Refer to
    # {https://github.com/octokit/octokit.rb
    # octokit.rb documentation}.
    #
    # @return [Octokit::Client]
    def init_client
      @client = Octokit::Client.new(login: 'me', oauth_token: options[:token])
      @client
    end

    # Pushes a list of {Item} to GitHub.
    #
    # @param items [Array<Item>]
    # @return [String] Commit SHA1 hash
    # @see Agent#push_items
    def push_all(items)
      source_sha = source_branch
      items.each { |item| source_sha = tree_append(source_sha, item) }
      commit = @client.create_commit(repo, options[:commit_msg], source_sha,
                                     target_branch)
      @client.update_ref(repo, "heads/#{options[:target]}", commit.sha)
      commit.sha
    end

    # Pushes a single {Item} to GitHub. This means making a new commit for each
    # file. Not recommended and should just use {#push_all} instead.
    #
    # @param item [Item]
    # @return [nil]
    def push_item(item)
      Worochi::Log.warn 'push_item should not be used for GitHub'
      push_all([item])
    end

    # Returns a list of files and subdirectories at the remote path specified
    # by `options[:dir]`.
    #
    # @param path [String] path to list instead of the current directory
    # @param sha [String] list a different branch than the `:source`
    # @return [Array<Hash>] list of files and subdirectories
    def list(path=nil, sha=nil)
      remote_path = list_path(path).sub(/^\//, '').sub(/\/$/, '')

      result = @client.tree(repo, sha || source_branch, recursive: true).tree
      result.sort! do |x, y|
        x.path.split('/').size <=> y.path.split('/').size
      end

      # Filters for folders containing the specified path
      result.reject! { |elem| !elem.path.match(remote_path + '($|\/.+)') }
      raise Error, 'Invalid GitHub path specified' if result.empty?

      # Filters out lower levels
      result.reject! do |elem|
        filename = elem.path.split('/').last
        File.join(remote_path, filename).sub(/^\//, '') != elem.path
      end

      result.map do |elem|
        {
          name: elem.path.split('/').last,
          path: elem.path,
          type: elem.type == 'tree' ? 'folder' : 'file',
          sha: elem.sha
        }
      end
    end

    # Returns a list of repositories for the remote branch specified by
    # `options[:source]`. If `opts[:push]` is `true`, then only repos with
    # push access are returned. If `opts[:details]` is `true`, returns hashes
    # containing more information about each repo.
    #
    # @param opts [Hash]
    # @return [Array<String>, Array<Hash>] a list of repositories    
    def repos(opts={ push: false, details: false, orgs: true })
      repos = @client.repositories.map {|repo| parse_repo repo}
      @client.organizations.each do |org|
        repos += @client.organization_repositories(org.login).map {|repo| parse_repo repo}
      end
      repos.reject! {|repo| !repo[:push]} if opts[:push]
      repos.map { |repo| repo[:full_name] } unless opts[:details]
    end

    # Deletion is not supported by GitHub, so raises {Error}.
    def delete(path)
      raise Error, 'Cannot delete from GitHub'
    end

  private
    # Appends an item to the existing tree.
    #
    # @param tree_sha [String] SHA1 checksum of the root tree
    # @param item [Item] the item to append
    # @return [String] SHA1 checksum of the resulting tree
    def tree_append(tree_sha, item)
      child = {
        path: full_path(item.path).gsub(/^\//, ''),
        sha: push_blob(item),
        type: 'blob',
        mode: '100644'
      }
      new_tree = @client.create_tree(repo, [child], base_tree: tree_sha)
      new_tree.sha
    end

    # Pushes a single item to GitHub and returns the blob SHA1 checksum.
    #
    # @param item [Item]
    # @return [String] SHA1 checksum of the created blob
    def push_blob(item)
      Worochi::Log.debug "Uploading #{item.path} (#{item.size} bytes) to GitHub..."
      if item.size > options[:block_size]
        sha = stream_blob(item)
      else
        sha = @client.create_blob(repo, Base64.strict_encode64(item.read),
                                  'base64')
      end
      Worochi::Log.debug "Uploaded [#{sha}]"
      sha
    end

    # Pushes a single item to GitHub using JSON streaming and returns the SHA1
    # checksum
    #
    # @param item [Item]
    # @return [String] SHA1 checksum of the created blob
    def stream_blob(item)
      Worochi::Log.debug "Using JSON streaming..."
      post_stream = Helper::StreamIO.new(item)

      uri = URI("https://api.github.com/repos/#{repo}/git/blobs")
      request = Net::HTTP::Post.new(uri.path)
      request.content_length = post_stream.size
      request.content_type = 'application/x-www-form-urlencoded'
      request.add_field('Authorization', "token #{options[:token]}")
      request.body_stream = post_stream

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.request request do |response|
        return JSON.parse(response.body)['sha']
      end
    end

    # @return [Hash] repo information
    def parse_repo(repo)
      {
        name: repo.name,
        full_name: repo.full_name,
        owner: repo.owner.login,
        description: repo.description,
        url: repo.url,
        push: repo.permissions.push,
        pull: repo.permissions.pull
      }
    end

    # Returns the SHA1 checksum of the source branch.
    #
    # @return [String] SHA1 checksum
    def source_branch
      @client.branch(repo, options[:source]).commit.sha
    end

    # Returns the SHA1 checksum of the target branch. Clones source branch if
    # target branch does not exist
    #
    # @return [String] SHA1 checksum
    def target_branch
      begin
        sha = @client.branch(repo, options[:target]).commit.sha
      rescue
        ref = @client.create_ref(repo, "heads/#{options[:target]}", source_branch)
        sha = ref.object.sha
      end
      sha
    end

    # An alias for `options[:repo]`
    #
    # @return [String] full repo name
    def repo
      options[:repo]
    end
  end
end