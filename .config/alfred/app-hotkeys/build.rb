#!/usr/bin/ruby
# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'shellwords'
require 'tempfile'

BUNDLE_ID = 'local.thj.app-hotkeys'
INSTALL_ID = '8395F5D9-F4D5-4C05-9382-8E035A90E159'
KEY_CODES = {
  'a' => 0, 'b' => 11, 'c' => 8, 'd' => 2, 'e' => 14, 'f' => 3,
  'g' => 5, 'h' => 4, 'i' => 34, 'j' => 38, 'k' => 40, 'l' => 37,
  'm' => 46, 'n' => 45, 'o' => 31, 'p' => 35, 'q' => 12, 'r' => 15,
  's' => 1, 't' => 17, 'u' => 32, 'v' => 9, 'w' => 13, 'x' => 7,
  'y' => 16, 'z' => 6
}.freeze
MODIFIERS = {
  'shift' => 131_072, 'ctrl' => 262_144, 'alt' => 524_288,
  'option' => 524_288, 'cmd' => 1_048_576
}.freeze

def uid(kind, id)
  hex = Digest::SHA256.hexdigest("#{BUNDLE_ID}/#{kind}/#{id}")[0, 32].upcase
  [hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]].join('-')
end

def parse_hotkey(value)
  return [-1, MODIFIERS.fetch('option'), 'double tap'] if value.to_s.downcase == 'option+option'

  parts = value.to_s.downcase.split('+')
  key = parts.pop
  raise ArgumentError, "unsupported hotkey: #{value}" unless KEY_CODES.key?(key) && parts.any?
  raise ArgumentError, "duplicate modifier in #{value}" unless parts.uniq.length == parts.length

  bits = parts.reduce(0) { |mask, part| mask | MODIFIERS.fetch(part) }
  [KEY_CODES.fetch(key), bits, key.upcase]
end

def plist_for(apps)
  objects = []
  connections = {}
  uidata = {}

  apps.each_with_index do |app, index|
    id = app.fetch('id')
    name = app.fetch('name')
    bundle_id = app.fetch('bundle_id')
    raise ArgumentError, "invalid app id: #{id}" unless id.match?(/\A[a-z][a-z0-9_-]*\z/)
    raise ArgumentError, "missing app name: #{id}" if name.to_s.empty?
    raise ArgumentError, "invalid bundle ID: #{id}" unless bundle_id.match?(/\A[a-zA-Z0-9.-]+\z/)

    key, modifiers, hotstring = parse_hotkey(app.fetch('hotkey'))
    trigger_uid = uid('hotkey', id)
    action_uid = uid('action', id)
    objects << {
      'type' => 'alfred.workflow.trigger.hotkey', 'uid' => trigger_uid, 'version' => 2,
      'config' => {
        'action' => 0, 'argument' => 0, 'focusedappvariable' => false,
        'focusedappvariablename' => '', 'hotkey' => key, 'hotmod' => modifiers,
        'hotstring' => hotstring, 'leftcursor' => false, 'modsmode' => 0,
        'relatedAppsMode' => 0
      }
    }
    objects << {
      'type' => 'alfred.workflow.action.script', 'uid' => action_uid, 'version' => 2,
      'config' => {
        'concurrently' => false, 'escaping' => 68,
        'script' => "/usr/bin/open -b #{Shellwords.escape(bundle_id)}",
        'scriptargtype' => 1, 'scriptfile' => '', 'type' => 0
      }
    }
    connections[trigger_uid] = [{
      'destinationuid' => action_uid, 'modifiers' => 0,
      'modifiersubtext' => '', 'vitoclose' => false
    }]
    uidata[trigger_uid] = { 'xpos' => 40, 'ypos' => 80 + index * 170 }
    uidata[action_uid] = { 'xpos' => 290, 'ypos' => 80 + index * 170 }
  end

  {
    'bundleid' => BUNDLE_ID, 'category' => 'Productivity',
    'connections' => connections, 'description' => 'Launch frequently used apps with hotkeys',
    'disabled' => false, 'name' => 'App Hotkeys', 'objects' => objects,
    'uidata' => uidata, 'userconfigurationconfig' => []
  }
end

def write_plist(path, document)
  xml, error, status = Open3.capture3('/usr/bin/plutil', '-convert', 'xml1', '-o', '-', '-',
                                      stdin_data: JSON.generate(document))
  abort error unless status.success?
  Tempfile.create(['info', '.plist'], File.dirname(path)) do |file|
    file.write(xml)
    file.flush
    File.rename(file.path, path)
  end
end

def installed_path
  prefs = JSON.parse(File.read(File.expand_path('~/Library/Application Support/Alfred/prefs.json')))
  workflows = File.join(prefs.fetch('current'), 'workflows')
  installed = Dir.glob(File.join(workflows, 'user.workflow.*', 'info.plist')).select do |path|
    data, status = Open3.capture2('/usr/bin/plutil', '-convert', 'json', '-o', '-', path)
    status.success? && JSON.parse(data)['bundleid'] == BUNDLE_ID
  end
  raise "multiple installed #{BUNDLE_ID} workflows" if installed.length > 1

  installed.first || File.join(workflows, "user.workflow.#{INSTALL_ID}", 'info.plist')
end

mode = ARGV.fetch(0) { abort 'Usage: build.rb --install|--package' }
abort 'Usage: build.rb --install|--package' unless %w[--install --package].include?(mode) && ARGV.length == 1

config = JSON.parse(File.read(File.join(__dir__, 'hotkeys.json')))
raise ArgumentError, 'version must be 1' unless config['version'] == 1
apps = config.fetch('apps')
raise ArgumentError, 'apps must be a nonempty array' unless apps.is_a?(Array) && !apps.empty?
raise ArgumentError, 'duplicate app IDs' unless apps.map { |app| app.fetch('id') }.uniq.length == apps.length
raise ArgumentError, 'duplicate hotkeys' unless apps.map { |app| app.fetch('hotkey').downcase }.uniq.length == apps.length

source = File.join(__dir__, 'info.plist')
write_plist(source, plist_for(apps))

if mode == '--install'
  destination = installed_path
  FileUtils.mkdir_p(File.dirname(destination))
  FileUtils.cp(source, destination)
  FileUtils.cp(File.join(__dir__, 'icon.png'), File.join(File.dirname(destination), 'icon.png'))
  puts "Installed #{apps.length} app hotkeys: #{destination}"
else
  output_dir = File.join(__dir__, 'dist')
  FileUtils.mkdir_p(output_dir)
  package = File.join(output_dir, 'App Hotkeys.alfredworkflow')
  FileUtils.rm_f(package)
  abort 'Could not package workflow' unless system('/usr/bin/zip', '-q', '-j', package, source, File.join(__dir__, 'icon.png'))
  puts package
end
