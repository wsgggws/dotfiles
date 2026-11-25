require "json"
require "net/http"
require "uri"
require "yaml"

CONFIG = File.expand_path("~/Library/Application Support/com.follow.clash/config.yaml")
GROUP = "节点选择"
INTERVAL = 120
FLCLASH_START_RETRY = 5
TIMEOUT_MS = 5_000
TEST_URL = "https://www.gstatic.com/generate_204"
HONG_KONG = /香港|Hong[ _-]*Kong|(?<![A-Za-z])HK(?![A-Za-z])|🇭🇰/i
JAPAN = /日本|东京|東京|大阪|Japan|(?<![A-Za-z])JP(?![A-Za-z])|🇯🇵/i

def proxy_path(name)
  "/proxies/#{URI.encode_www_form_component(name).gsub('+', '%20')}"
end

def request(http, secret, verb, path, body = nil)
  message = verb.new(path)
  message["Authorization"] = "Bearer #{secret}"
  if body
    message["Content-Type"] = "application/json"
    message.body = JSON.generate(body)
  end
  http.request(message)
end

def read_group(http, secret, path)
  response = request(http, secret, Net::HTTP::Get, path)
  raise "读取策略组失败，HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

  group = JSON.parse(response.body)
  raise "策略组需要保持手动选择类型" unless group["type"] == "Selector"

  group
end

def healthy?(http, secret, proxy)
  query = URI.encode_www_form(url: TEST_URL, timeout: TIMEOUT_MS, expected: 204)
  response = request(http, secret, Net::HTTP::Get, "#{proxy_path(proxy)}/delay?#{query}")
  return false if %w[503 504].include?(response.code)
  raise "节点检测接口返回 HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

  delay = JSON.parse(response.body).fetch("delay")
  delay.is_a?(Numeric) && delay.positive?
end

def candidates_in_order(nodes)
  hong_kong, remaining = nodes.partition { |name| HONG_KONG.match?(name) }
  japan, remaining = remaining.partition { |name| JAPAN.match?(name) }
  hong_kong + japan + remaining
end

def check(config, apply)
  binding = config.fetch("external-controller", "")
  host, port = binding.split(":", 2)
  unless host == "127.0.0.1" && port.to_s.match?(/\A\d+\z/) && (1..65535).cover?(port.to_i)
    raise "需要 FlClash 的本机控制器 127.0.0.1"
  end
  secret = config.fetch("secret", "").to_s
  raise "未找到 FlClash 控制器密钥" if secret.empty?

  http = Net::HTTP.new(host, port.to_i, nil)
  http.open_timeout = 2
  http.read_timeout = 8
  path = proxy_path(GROUP)
  group = read_group(http, secret, path)
  concrete_nodes = config.fetch("proxies", []).map { |proxy| proxy.fetch("name") }
  nodes = group.fetch("all") & concrete_nodes
  current = group.fetch("now")
  return "请在「节点选择」中选一个具体节点作为起点" unless nodes.include?(current)

  return "当前节点可用，继续使用 #{current}" if healthy?(http, secret, current)
  sleep 2
  return "当前节点复测可用，继续使用 #{current}" if healthy?(http, secret, current)

  replacement = candidates_in_order(nodes - [current]).find { |node| healthy?(http, secret, node) }
  return "本轮未找到可用节点" unless replacement
  return "预览结果，建议切到 #{replacement}" unless apply

  latest = read_group(http, secret, path)
  return "策略组已更新，下轮重新检测" unless latest["now"] == current && latest["all"].include?(replacement)

  response = request(http, secret, Net::HTTP::Put, path, { name: replacement })
  raise "切换失败，HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
  return "切换后策略组再次更新，下轮重新检测" unless read_group(http, secret, path)["now"] == replacement

  "已从 #{current} 切换到 #{replacement}"
end

def run_monitor(mode)
  watch = !mode.nil?
  background = mode == "--background"
  was_waiting = false
  $stdout.sync = true

  loop do
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    delay = INTERVAL
    waiting = false
    output = $stdout
    begin
      config = YAML.safe_load(File.read(CONFIG), aliases: true)
      message = check(config, watch)
    rescue SystemCallError, IOError, Net::OpenTimeout, Net::ReadTimeout, JSON::ParserError, Psych::Exception => error
      if background && (error.is_a?(Errno::ENOENT) || error.is_a?(Errno::ECONNREFUSED))
        message = "等待 FlClash 启动"
        delay = FLCLASH_START_RETRY
        waiting = true
      else
        message = "暂时无法读取 FlClash 配置或连接控制器（#{error.class}）"
        output = $stderr
      end
    rescue KeyError, RuntimeError => error
      message = error.message
      output = $stderr
    end

    if output == $stderr && !watch
      warn message
      exit 1
    end

    unless waiting && was_waiting
      output.puts "[#{Time.now.strftime('%F %T')}] #{message}"
    end
    was_waiting = waiting

    break unless watch
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    sleep [delay - elapsed, 0].max
  end
end

if $PROGRAM_NAME == __FILE__
  unless ARGV.empty? || ARGV == ["--watch"] || ARGV == ["--background"]
    abort "用法：ruby #{File.basename(__FILE__)} [--watch|--background]"
  end

  run_monitor(ARGV.first)
end
