require 'rye'
require 'benchmark'
require 'json'

module Bungee
  class Backup
    attr_reader :hosts, :index, :elasticsearch_url, :first_host, :cluster, :data_path

    def initialize(options = {})
      @index = options[:index]
      @elasticsearch_url = options[:elasticsearch_url] || 'http://localhost:9200'
      @data_path = options[:data_path]
      @backup_path = options[:backup_path]

      @hosts = Rye::Set.new('default', :safe => false)
      boxes = options[:hosts].map { |host| Rye::Box.new(host, :safe => false) }
      @first_host = boxes.first
      @hosts.add_boxes(boxes)
    end

    def backup!
      flush_index
      disable_translog_flushing
      rsync_index_locally
      enable_translog_flushing
      merge_shards_to_backup_path
    end

    protected

    def flush_index
      es_request('POST', "/#{index}/_flush")
    end

    def disable_translog_flushing
      set_translog_disable_flush(true)
    end

    def enable_translog_flushing
      set_translog_disable_flush(false)
    end

    def set_translog_disable_flush(status)
      es_request("PUT", "/#{index}/_settings", {
        'index.translog.disable_flush' => status
      })
    end

    def rsync_index_locally
      puts "rsyncing to local copy"
      hosts.parallel = true
      time("Local Rsync") do
        hosts.rsync("-rpvi", "--delete", "#{data_path}/nodes/0/indices/#{index}/", "/tmp/bungee_#{index}")
      end
    end

    def merge_shards_to_backup_path
      puts "merging shards"
      first, *rest = hosts.boxes
      # Delete to clean out the folder
      time("First RSync") do
        first.rsync("-rpvi", "--delete", "/tmp/bungee_#{index}/", @backup_path)
      end
      rest.each do |box|
        time("Rsync") do
          box.rsync("-rpvi", "/tmp/bungee_#{index}/", @backup_path)
        end
      end
    end

    def time(caption, &block)
      puts caption
      puts Benchmark.measure(&block)
    end

    def es_request(verb, path, data = nil)
      args = ["-s", "-X", verb, "#{elasticsearch_url}#{path}"]
      args << "-d" << "'#{JSON.dump(data)}'" if data
      puts "Performing: #{args.join(' ')}"
      ret = first_host.curl(*args)
      if ret.exit_status.zero?
        out = JSON.parse(ret.to_s)
      else
        $stderr.puts("Error performing command: #{ret.cmd}")
        $stderr.puts("Stdout:")
        $stderr.puts(ret.stdout)
        $stderr.puts("Stderr:")
        $stderr.puts(ret.stderr)
        $stderr.puts("Exit Code: #{ret.exit_status}")
        nil
      end
    end
  end
end
