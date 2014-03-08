#!/usr/bin/env ruby

require 'getoptlong'
require 'open-uri'
require 'open3'

begin
  require 'nokogiri'
rescue LoadError
  $stderr << "Install nokogiri (gem install nokogiri).\n"
  exit 1
end

class Pkgbuild
  attr_reader :version, :timestamp

  def initialize(hash: false)
    @version, @timestamp = versions
    @hash = hash
  end

  def major
    version.segments[0..1].join('.')
  end

  def update!(patch)
    c = File.open('PKGBUILD').readlines

    c.each_with_index do |line, i|
      if line =~ /^_basekernel=/
        c[i] = "_basekernel=#{patch.major}\n"
      end

      if line =~ /^pkgver=/
        c[i] = "pkgver=${_basekernel}.#{patch.version.segments.last}\n"
      end

      if line =~ /^_timestamp=/
        c[i] = "_timestamp=#{patch.timestamp}\n"
      end

      if line =~ /^pkgrel=/
        new = 1
        new = line.split('=').last.to_i + 1 if version == patch.version
        c[i] = "pkgrel=#{new}\n"
      end

      if @hash && line =~ /^sha256sums=/
        c = c.first(i)
      end
    end

    write c.join

    if @hash
      o, e, s = Open3.capture3 'makepkg -g'
      c << o if s.success?
    end

    write c.join
  end

  private

  def versions
    v, t = `bash PKGBUILD -v`.split ' '
    [Gem::Version.new(v), t.to_i]
  end

  def write(contents)
    File.open('PKGBUILD', 'w').write contents
  end
end

class Patch
  URI = 'http://grsecurity.net/download.php'

  attr_reader :version, :timestamp

  def initialize
    @version, @timestamp = versions
  end

  def filename
    unless @filename
      doc = Nokogiri::HTML open URI
      patches = doc.css('div.left a').map &:content
      v = newest patches
      @filename = patches.select { |x| x.include? v }.first
    end

    @filename
  end

  def major
    version.segments[0..1].join('.')
  end

  private

  def newest(patches)
    select_version patches, :last
  end

  def select_version(patches, method)
    a = patches.sort.map { |x| x.split('-')[2] }
    a.select! { |x| x =~ /^[0-9]{1}\./ }
    a.map! { |x| Gem::Version.new x rescue nil }
    a.sort.send(method).to_s
  end

  def versions
    v, t = filename.split('-')[2..3]
    t = t.split('.').first
    [Gem::Version.new(v), t.to_i]
  end
end

def usage_message
  $stderr << "#{File.basename $0} [options]
Update version and patch in linux-grsec PKGBUILD.

  -G  Generate new hashes and append them to PKGBUILD.
  -h  This help.

"
  exit 1
end

hash = true

options = GetoptLong.new \
  [ '-G', GetoptLong::NO_ARGUMENT ],
  [ '-h', GetoptLong::NO_ARGUMENT ]

options.each do |option, argument|
  case option
  when '-G'
    hash = false
  when '-h'
    usage_message
  end
end

pkgbuild = Pkgbuild.new hash: hash
patch = Patch.new

if pkgbuild.timestamp < patch.timestamp
  pkgbuild.update! patch
  puts `git diff PKGBUILD`
else
  puts 'PKGBUILD is up-to-date.'
end
