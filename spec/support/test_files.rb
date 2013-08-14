module TestFiles
  # Remote file for testing.
  def remote
    @remote ||= OpenStruct.new({
      source: 'http://soraven.com/blog/wp-content/uploads/2013/06/sr3.gif',
      checksum: '3c0d873709da4a08e9d9978f678dbc30a6cc5138182c2fee56db1c0b8b806d67',
      name: 'sr3.gif',
      path: '/folder1/sr3.gif',
      file_size: 2985
    })
  end

  # Local file for testing.
  def local
    @local ||= Hashie::Mash.new({
      source: File.join(File.dirname(__FILE__), 'test_file'),
      checksum: '798d1088d589c155841cfd6ddd5c8254e883d49220d3a60c10d0f77ce96a5ac4',
      name: 'test_file',
      path: '/folder2/test_file',
      file_size: File.open(File.join(File.dirname(__FILE__), 'test_file')).size
    })
  end

  # Amazon S3 file for testing.
  def s3
    @s3 ||= OpenStruct.new({
      source: 's3:12061/271934/orig_232903',
      checksum: 'f0891f199f0966ec1b1d209b91ff3f51273577944dbbe338f1947ae9f33cb79a',
      name: '__init__.py',
      path: '/folder3/__init__.py',
      file_size: 8
    })
  end
end