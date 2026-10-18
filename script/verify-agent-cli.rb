#!/usr/bin/env ruby
# Hardware integration checks. All captures stay in the supplied evidence directory.
require 'json'
require 'open3'
require 'digest'
require 'fileutils'
cli = File.expand_path(ARGV.fetch(0))
root = File.expand_path(ARGV.fetch(1))
FileUtils.mkdir_p(root)
checks = []
owned_recording = false
invoke = lambda do |*args|
  out, err, status = Open3.capture3(cli, *args)
  [JSON.parse(out), status.exitstatus, err]
end
begin
  caps, code = invoke.call('capabilities')
  raise 'Capability discovery failed' unless code == 0 && caps['schema_version'] == 1
  checks << { check: 'capabilities', passed: true }
  list, code = invoke.call('screens')
  raise 'No screen found' unless code == 0 && !list['screens'].empty?
  screen = list['screens'].length > 1 ? 1 : 0
  checks << { check: 'screen_discovery', passed: true, screens: list['screens'] }
  directory = File.join(root, 'agent 项目', '截图')
  shot, code = invoke.call('screenshot', '--screen', screen.to_s, '--region', '100,120,320,200', '--quality', 'high', '--directory', directory, '--prefix', 'agent 设计')
  raise "Screenshot failed: #{shot}" unless code == 0 && shot['path'].start_with?(directory + '/agent 设计_')
  raise 'Incorrect PNG dimensions' unless File.binread(shot['path'], 24).byteslice(16, 8).unpack('NN') == [640, 400]
  checks << { check: 'unicode_destination_prefix_and_retina', passed: true, result: shot }
  hash = Digest::SHA256.file(shot['path']).hexdigest
  collision, code = invoke.call('screenshot', '--region', '100,120,320,200', '--output', shot['path'])
  raise 'Screenshot overwrite was allowed' unless code == 1 && collision['error'] && hash == Digest::SHA256.file(shot['path']).hexdigest
  checks << { check: 'screenshot_no_overwrite', passed: true }
  [
    ['invalid_quality', ['screenshot', '--quality', 'invalid']],
    ['missing_display', ['screenshot', '--screen', '999']],
    ['invalid_region', ['screenshot', '--region=-1,0,20,20']],
    ['conflicting_options', ['screenshot', '--output', shot['path'], '--directory', directory]],
    ['record_invalid_quality', ['record', 'start', '--quality', 'invalid']],
    ['record_existing_output', ['record', 'start', '--output', shot['path']]],
    ['record_missing_display', ['record', 'start', '--screen', '999']],
    ['record_invalid_region', ['record', 'start', '--region=-1,0,20,20']]
  ].each do |name, args|
    response, code = invoke.call(*args)
    raise "#{name} did not return a JSON error" unless code == 1 && response['error']
    checks << { check: name, passed: true, error: response['error'] }
  end
  recording_directory = File.join(root, 'agent 项目', '录像')
  start, code = invoke.call('record', 'start', '--screen', screen.to_s, '--region', '100,120,200,100', '--quality', 'high', '--directory', recording_directory, '--prefix', 'agent 录像')
  raise "Recording start failed: #{start}" unless code == 0 && start['status'] == 'recording'
  owned_recording = true
  sleep 2
  stop, code = invoke.call('record', 'stop')
  owned_recording = false
  raise "Recording stop failed: #{stop}" unless code == 0 && stop['duration_s'] > 0 && File.size(stop['path']) > 0 && stop['path'].start_with?(recording_directory + '/agent 录像_')
  checks << { check: 'record_start_stop_playable', passed: true, start: start, stop: stop }
  File.write(File.join(root, 'agent-checks.json'), JSON.pretty_generate(checks) + "\n")
  puts "#{checks.length} agent CLI hardware checks passed"
ensure
  invoke.call('record', 'stop') if owned_recording
end
