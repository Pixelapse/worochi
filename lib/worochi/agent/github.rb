require 'octokit'
require 'base64'
require 'worochi/helper/github'

class Worochi
  class Agent::Github < Agent

    # General agent methods

    def default_options
      {
        source: 'master',
        target: 'worochi',
        repo: 'darkmirage/test',
        block_size: Worochi::Helper::Github::StreamIO::BLOCK_SIZE,
        commit_msg: 'Empty commit message',
        dir: '/'
      }
    end

    def init_client
      @client = Octokit::Client.new(login: 'me', oauth_token: options[:token])
    end

    def push_all(items)
      source_sha = source_branch
      items.each { |item| source_sha = tree_append(source_sha, item) }
      commit = @client.create_commit(repo, options[:commit_msg], source_sha, target_branch)
      @client.update_ref(repo, "heads/#{options[:target]}", commit.sha)
    end

    # Pushing a single file using GitHub means making a new commit for each
    # file. Not recommened and should just use push_all instead.
    def push_file(item)
      Worochi::Log.warn 'push_file should not be used for GitHub'
      push_all([item])
    end

    def folders
      remote_path = options[:dir].sub(/^\//, '').sub(/\/$/, '')
      source_sha = source_branch
      list = get_folder_list(source_sha)
      # Checks that folders are at the requested path
      list.reject! do |folder|
        !folder.path.match(remote_path + '($|\/.+)') || (
          File.join(remote_path,
            folder.path.split('/').last).sub(/^\//, '') != folder.path
        )
      end
      list.map do |item|
        {
          name: item.path.split('/').last,
          path: item.path,
          type: item.type == 'tree' ? 'dir' : 'file',
          sha: item.sha
        }
      end
    end

    # GitHub specific methods

    def repos(push_only=false)
      repos = @client.repositories.map {|repo| parse_repo repo}
      @client.organizations.each do |org|
        repos += @client.organization_repositories(org.login).map {|repo| parse_repo repo}
      end
      repos.reject! {|repo| !repo[:push]} if push_only
      repos
    end

    def tree_append(tree_sha, item)
      child = {
        path: full_path(item).gsub(/^\//, ''),
        sha: push_blob(item),
        type: 'blob',
        mode: '100644'
      }
      new_tree = @client.create_tree(repo, [child], base_tree: tree_sha)
      new_tree.sha
    end

    def push_blob(item)
      Worochi::Log.debug "Uploading #{item.path} (#{item.size} bytes) to GitHub..."
      if item.size > options[:block_size]
        sha = stream_blob(item)
      else
        sha = @client.create_blob(repo, Base64.strict_encode64(item.read), 'base64')
      end
      Worochi::Log.debug "Uploaded [#{sha}]"
      sha
    end

    def stream_blob(item)
      Worochi::Log.debug "Using JSON streaming..."
      post_stream = Worochi::Helper::Github::StreamIO.new(item.content)

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

      raise Error, 'Failed to upload file to GitHub'
    end

    def get_folder_list(root_sha)
      folder_list = @client.tree(repo, root_sha, :recursive => true).tree
      folder_list.sort! {|x, y| x.path.split('/').size <=> y.path.split('/').size}
    end

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

    def source_branch
      @client.branch(repo, options[:source]).commit.sha
    end

    def target_branch
      begin
        sha = @client.branch(repo, options[:target]).commit.sha
      rescue
        # Clones source branch if target branch does not exist
        ref = @client.create_ref(repo, "heads/#{options[:target]}", source_branch)
        sha = ref.object.sha
      end
      sha
    end

    def set_source(source)
      options[:source] = source
    end

    def repo
      options[:repo]
    end
  end
end